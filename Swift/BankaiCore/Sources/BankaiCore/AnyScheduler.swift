//
//  AnyScheduler.swift
//  
//
//  Created by Sergio Daniel on 1/09/24.
//

#if canImport(Combine)
  import Combine
  import Foundation

  /// A type-erasing wrapper for the `Scheduler` protocol, which can be useful for being generic over
  /// many types of schedulers without needing to actually introduce a generic to your code.
  ///
  /// This type is useful for times that you want to be able to customize the scheduler used in some
  /// code from the outside, but you don't want to introduce a generic to make it customizable. For
  /// example, suppose you have a view model `ObservableObject` that performs an API request when a
  /// method is called:
  ///
  /// ```swift
  /// class EpisodeViewModel: ObservableObject {
  ///   @Published var episode: Episode?
  ///
  ///   let apiClient: ApiClient
  ///
  ///   init(apiClient: ApiClient) {
  ///     self.apiClient = apiClient
  ///   }
  ///
  ///   func reloadButtonTapped() {
  ///     self.apiClient.fetchEpisode()
  ///       .receive(on: DispatchQueue.main)
  ///       .assign(to: &self.$episode)
  ///   }
  /// }
  /// ```
  ///
  /// Notice that we are using `DispatchQueue.main` in the `reloadButtonTapped` method because the
  /// `fetchEpisode` endpoint most likely delivers its output on a background thread (as is the case
  /// with `URLSession`).
  ///
  /// This code seems innocent enough, but the presence of `.receive(on: DispatchQueue.main)` makes
  /// this code harder to test since you have to use `XCTest` expectations to explicitly wait a small
  /// amount of time for the queue to execute. This can lead to flakiness in tests and make test
  /// suites take longer to execute than necessary.
  ///
  /// One way to fix this testing problem is to use an "immediate" scheduler instead of
  /// `DispatchQueue.main`, which will cause `fetchEpisode` to deliver its output as soon as possible
  /// with no thread hops. In order to allow for this we would need to inject a scheduler into our
  /// view model so that we can control it from the outside:
  ///
  /// ```swift
  /// class EpisodeViewModel<S: Scheduler>: ObservableObject {
  ///   @Published var episode: Episode?
  ///
  ///   let apiClient: ApiClient
  ///   let scheduler: S
  ///
  ///   init(apiClient: ApiClient, scheduler: S) {
  ///     self.apiClient = apiClient
  ///     self.scheduler = scheduler
  ///   }
  ///
  ///   func reloadButtonTapped() {
  ///     self.apiClient.fetchEpisode()
  ///       .receive(on: self.scheduler)
  ///       .assign(to: &self.$episode)
  ///   }
  /// }
  /// ```
  ///
  /// Now we can initialize this view model in production by using `DispatchQueue.main` and we can
  /// initialize it in tests using `DispatchQueue.immediate`. Sounds like a win!
  ///
  /// However, introducing this generic to our view model is quite heavyweight as it is loudly
  /// announcing to the outside world that this type uses a scheduler, and worse it will end up
  /// infecting any code that touches this view model that also wants to be testable. For example,
  /// any view that uses this view model will need to introduce a generic if it wants to also be able
  /// to control the scheduler, which would be useful if we wanted to write snapshot tests.
  ///
  /// Instead of introducing a generic to allow for substituting in different schedulers we can use
  /// `AnyScheduler`. It allows us to be somewhat generic in the scheduler, but without actually
  /// introducing a generic.
  ///
  /// Instead of holding a generic scheduler in our view model we can say that we only want a
  /// scheduler whose associated types match that of `DispatchQueue`:
  ///
  /// ```swift
  /// class EpisodeViewModel: ObservableObject {
  ///   @Published var episode: Episode?
  ///
  ///   let apiClient: ApiClient
  ///   let scheduler: AnySchedulerOf<DispatchQueue>
  ///
  ///   init(apiClient: ApiClient, scheduler: AnySchedulerOf<DispatchQueue>) {
  ///     self.apiClient = apiClient
  ///     self.scheduler = scheduler
  ///   }
  ///
  ///   func reloadButtonTapped() {
  ///     self.apiClient.fetchEpisode()
  ///       .receive(on: self.scheduler)
  ///       .assign(to: &self.$episode)
  ///   }
  /// }
  /// ```
  ///
  /// Then, in production we can create a view model that uses a live `DispatchQueue`, but we just
  /// have to first erase its type:
  ///
  /// ```swift
  /// let viewModel = EpisodeViewModel(
  ///   apiClient: ...,
  ///   scheduler: DispatchQueue.main.eraseToAnyScheduler()
  /// )
  /// ```
  ///
  /// For common schedulers, like `DispatchQueue`, `OperationQueue`, and `RunLoop`, there is even a
  /// static helper on `AnyScheduler` that further simplifies this:
  ///
  /// ```swift
  /// let viewModel = EpisodeViewModel(
  ///   apiClient: ...,
  ///   scheduler: .main
  /// )
  /// ```
  ///
  /// And in tests we can use an immediate scheduler:
  ///
  /// ```swift
  /// let viewModel = EpisodeViewModel(
  ///   apiClient: ...,
  ///   scheduler: .immediate
  /// )
  /// ```
  ///
  /// So, in general, `AnyScheduler` is great for allowing one to control what scheduler is used
  /// in classes, functions, etc. without needing to introduce a generic, which can help simplify
  /// the code and reduce implementation details from leaking out.
  ///
  public struct AnyScheduler<
    SchedulerTimeType: Strideable, SchedulerOptions
  >: Scheduler, @unchecked Sendable
  where SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _now: () -> SchedulerTimeType
    private let _scheduleAfterIntervalToleranceOptionsAction:
      (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
      ) -> Cancellable
    private let _scheduleAfterToleranceOptionsAction:
      (
        SchedulerTimeType,
        SchedulerTimeType.Stride,
        SchedulerOptions?,
        @escaping () -> Void
      ) -> Void
    private let _scheduleOptionsAction: (SchedulerOptions?, @escaping () -> Void) -> Void

    /// The minimum tolerance allowed by the scheduler.
    public var minimumTolerance: SchedulerTimeType.Stride { self._minimumTolerance() }

    /// This scheduler’s definition of the current moment in time.
    public var now: SchedulerTimeType { self._now() }

    /// Creates a type-erasing scheduler to wrap the provided endpoints.
    ///
    /// - Parameters:
    ///   - minimumTolerance: A closure that returns the scheduler's minimum tolerance.
    ///   - now: A closure that returns the scheduler's current time.
    ///   - scheduleImmediately: A closure that schedules a unit of work to be run as soon as possible.
    ///   - delayed: A closure that schedules a unit of work to be run after a delay.
    ///   - interval: A closure that schedules a unit of work to be performed on a repeating interval.
    public init(
      minimumTolerance: @escaping () -> SchedulerTimeType.Stride,
      now: @escaping () -> SchedulerTimeType,
      scheduleImmediately: @escaping (SchedulerOptions?, @escaping () -> Void) -> Void,
      delayed: @escaping (
        SchedulerTimeType, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void
      ) -> Void,
      interval: @escaping (
        SchedulerTimeType, SchedulerTimeType.Stride, SchedulerTimeType.Stride, SchedulerOptions?,
        @escaping () -> Void
      ) -> Cancellable
    ) {
      self._minimumTolerance = minimumTolerance
      self._now = now
      self._scheduleOptionsAction = scheduleImmediately
      self._scheduleAfterToleranceOptionsAction = delayed
      self._scheduleAfterIntervalToleranceOptionsAction = interval
    }

    /// Creates a type-erasing scheduler to wrap the provided scheduler.
    ///
    /// - Parameters:
    ///   - scheduler: A scheduler to wrap with a type-eraser.
    public init<S: Scheduler<SchedulerTimeType>>(
      _ scheduler: S
    ) where S.SchedulerOptions == SchedulerOptions {
      self._now = { scheduler.now }
      self._minimumTolerance = { scheduler.minimumTolerance }
      self._scheduleAfterToleranceOptionsAction = scheduler.schedule
      self._scheduleAfterIntervalToleranceOptionsAction = scheduler.schedule
      self._scheduleOptionsAction = scheduler.schedule
    }

    /// Performs the action at some time after the specified date.
    public func schedule(
      after date: SchedulerTimeType,
      tolerance: SchedulerTimeType.Stride,
      options: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) {
      self._scheduleAfterToleranceOptionsAction(date, tolerance, options, action)
    }

    /// Performs the action at some time after the specified date, at the
    /// specified frequency, taking into account tolerance if possible.
    public func schedule(
      after date: SchedulerTimeType,
      interval: SchedulerTimeType.Stride,
      tolerance: SchedulerTimeType.Stride,
      options: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) -> Cancellable {
      self._scheduleAfterIntervalToleranceOptionsAction(
        date, interval, tolerance, options, action)
    }

    /// Performs the action at the next possible opportunity.
    public func schedule(
      options: SchedulerOptions?,
      _ action: @escaping () -> Void
    ) {
      self._scheduleOptionsAction(options, action)
    }
  }

  /// A convenience type to specify an `AnyScheduler` by the scheduler it wraps rather than by the
  /// time type and options type.
  public typealias AnySchedulerOf<Scheduler> = AnyScheduler<
    Scheduler.SchedulerTimeType, Scheduler.SchedulerOptions
  > where Scheduler: Combine.Scheduler

  extension Scheduler {
    /// Wraps this scheduler with a type eraser.
    public func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
      AnyScheduler(self)
    }
  }

  extension AnySchedulerOf<DispatchQueue> {
    /// A type-erased main dispatch queue.
    public static var main: Self {
      DispatchQueue.main.eraseToAnyScheduler()
    }

    /// A type-erased global dispatch queue with the specified quality-of-service class
    public static func global(qos: DispatchQoS.QoSClass = .default) -> Self {
      DispatchQueue.global(qos: qos).eraseToAnyScheduler()
    }
  }

  extension AnyScheduler
  where
    SchedulerTimeType == OperationQueue.SchedulerTimeType,
    SchedulerOptions == OperationQueue.SchedulerOptions
  {
    /// A type-erased main operation queue.
    public static var main: Self {
      OperationQueue.main.eraseToAnyScheduler()
    }
  }

  extension AnyScheduler
  where
    SchedulerTimeType == RunLoop.SchedulerTimeType,
    SchedulerOptions == RunLoop.SchedulerOptions
  {
    /// A type-erased main run loop.
    public static var main: Self {
      RunLoop.main.eraseToAnyScheduler()
    }
  }

  extension AnyScheduler
  where
    SchedulerTimeType == DispatchQueue.SchedulerTimeType,
    SchedulerOptions == Never
  {
    /// The type-erased UI scheduler shared instance.
    ///
    /// The UI scheduler is a scheduler that executes its work on the main
    /// queue as soon as possible (avoiding unnecessary thread hops). See
    /// `UIScheduler` for more information.
    public static var shared: Self {
      UIScheduler.shared.eraseToAnyScheduler()
    }
  }
#endif

#if canImport(Combine)
  import Combine

  #if swift(>=6)
    @preconcurrency import Dispatch
  #else
    import Dispatch
  #endif

  /// A scheduler that executes its work on the main queue as soon as possible.
  ///
  /// This scheduler is inspired by the
  /// [equivalent](https://github.com/ReactiveCocoa/ReactiveSwift/blob/58d92aa01081301549c48a4049e215210f650d07/Sources/Scheduler.swift#L92)
  /// scheduler in the [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) project.
  ///
  /// If `UIScheduler.shared.schedule` is invoked from the main thread then the unit of work will be
  /// performed immediately. This is in contrast to `DispatchQueue.main.schedule`, which will incur
  /// a thread hop before executing since it uses `DispatchQueue.main.async` under the hood.
  ///
  /// This scheduler can be useful for situations where you need work executed as quickly as
  /// possible on the main thread, and for which a thread hop would be problematic, such as when
  /// performing animations.
  public struct UIScheduler: Scheduler, Sendable {
    public typealias SchedulerOptions = Never
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType

    /// The shared instance of the UI scheduler.
    ///
    /// You cannot create instances of the UI scheduler yourself. Use only the shared instance.
    public static let shared = Self()

    public var now: SchedulerTimeType { DispatchQueue.main.now }
    public var minimumTolerance: SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }

    public func schedule(options: SchedulerOptions? = nil, _ action: @escaping () -> Void) {
      if DispatchQueue.getSpecific(key: key) == value {
        action()
      } else {
        DispatchQueue.main.schedule(action)
      }
    }

    public func schedule(
      after date: SchedulerTimeType,
      tolerance: SchedulerTimeType.Stride,
      options: SchedulerOptions? = nil,
      _ action: @escaping () -> Void
    ) {
      DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil, action)
    }

    public func schedule(
      after date: SchedulerTimeType,
      interval: SchedulerTimeType.Stride,
      tolerance: SchedulerTimeType.Stride,
      options: SchedulerOptions? = nil,
      _ action: @escaping () -> Void
    ) -> Cancellable {
      DispatchQueue.main.schedule(
        after: date, interval: interval, tolerance: tolerance, options: nil, action
      )
    }

    private init() {
      DispatchQueue.main.setSpecific(key: key, value: value)
    }
  }

  private let key = DispatchSpecificKey<UInt8>()
  private let value: UInt8 = 0
#endif

#if canImport(Combine)
  import Combine
  import Foundation

  /// A scheduler for performing synchronous actions.
  ///
  /// You can only use this scheduler for immediate actions. If you attempt to schedule actions
  /// after a specific date, this scheduler ignores the date and performs them immediately.
  ///
  /// This scheduler is useful for writing tests against publishers that use asynchrony operators,
  /// such as `receive(on:)`, `subscribe(on:)` and others, because it forces the publisher to emit
  /// immediately rather than needing to wait for thread hops or delays using `XCTestExpectation`.
  ///
  /// This scheduler is different from `TestScheduler` in that you cannot explicitly control how
  /// time flows through your publisher, but rather you are instantly collapsing time into a single
  /// point.
  ///
  /// As a basic example, suppose you have a view model that loads some data after waiting for 10
  /// seconds from when a button is tapped:
  ///
  /// ```swift
  /// class HomeViewModel: ObservableObject {
  ///   @Published var episodes: [Episode]?
  ///
  ///   let apiClient: ApiClient
  ///
  ///   init(apiClient: ApiClient) {
  ///     self.apiClient = apiClient
  ///   }
  ///
  ///   func reloadButtonTapped() {
  ///     Just(())
  ///       .delay(for: .seconds(10), scheduler: DispatchQueue.main)
  ///       .flatMap { apiClient.fetchEpisodes() }
  ///       .assign(to: &self.episodes)
  ///   }
  /// }
  /// ```
  ///
  /// In order to test this code you would literally need to wait 10 seconds for the publisher to
  /// emit:
  ///
  /// ```swift
  /// func testViewModel() {
  ///   let viewModel = HomeViewModel(apiClient: .mock)
  ///
  ///   viewModel.reloadButtonTapped()
  ///
  ///   _ = XCTWaiter.wait(for: [XCTestExpectation()], timeout: 10)
  ///
  ///   XCTAssert(viewModel.episodes, [Episode(id: 42)])
  /// }
  /// ```
  ///
  /// Alternatively, we can explicitly pass a scheduler into the view model initializer so that it
  /// can be controller from the outside:
  ///
  /// ```swift
  /// class HomeViewModel: ObservableObject {
  ///   @Published var episodes: [Episode]?
  ///
  ///   let apiClient: ApiClient
  ///   let scheduler: AnySchedulerOf<DispatchQueue>
  ///
  ///   init(apiClient: ApiClient, scheduler: AnySchedulerOf<DispatchQueue>) {
  ///     self.apiClient = apiClient
  ///     self.scheduler = scheduler
  ///   }
  ///
  ///   func reloadButtonTapped() {
  ///     Just(())
  ///       .delay(for: .seconds(10), scheduler: self.scheduler)
  ///       .flatMap { self.apiClient.fetchEpisodes() }
  ///       .assign(to: &self.$episodes)
  ///   }
  /// }
  /// ```
  ///
  /// And then in tests use an immediate scheduler:
  ///
  /// ```swift
  /// func testViewModel() {
  ///   let viewModel = HomeViewModel(
  ///     apiClient: .mock,
  ///     scheduler: .immediate
  ///   )
  ///
  ///   viewModel.reloadButtonTapped()
  ///
  ///   // No more waiting...
  ///
  ///   XCTAssert(viewModel.episodes, [Episode(id: 42)])
  /// }
  /// ```
  ///
  /// > Note: This scheduler can _not_ be used to test publishers with more complex timing logic,
  /// > like those that use `Debounce`, `Throttle`, or `Timer.Publisher`, and in fact
  /// > `ImmediateScheduler` will not schedule this work in a defined way. Use a `TestScheduler`
  /// > instead to capture your publisher's timing behavior.
  ///
  public struct ImmediateScheduler<SchedulerTimeType: Strideable, SchedulerOptions>: Scheduler
  where SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {
    public let minimumTolerance: SchedulerTimeType.Stride = .zero
    public let now: SchedulerTimeType

    /// Creates an immediate test scheduler with the given date.
    ///
    /// - Parameter now: The current date of the test scheduler.
    public init(now: SchedulerTimeType) {
      self.now = now
    }

    public func schedule(options _: SchedulerOptions?, _ action: () -> Void) {
      action()
    }

    public func schedule(
      after _: SchedulerTimeType,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: () -> Void
    ) {
      action()
    }

    public func schedule(
      after _: SchedulerTimeType,
      interval _: SchedulerTimeType.Stride,
      tolerance _: SchedulerTimeType.Stride,
      options _: SchedulerOptions?,
      _ action: () -> Void
    ) -> Cancellable {
      action()
      return AnyCancellable {}
    }
  }

  extension ImmediateScheduler: Sendable
  where SchedulerTimeType: Sendable, SchedulerTimeType.Stride: Sendable {}

  extension DispatchQueue {
    /// An immediate scheduler that can substitute itself for a dispatch queue.
    public static var immediate: ImmediateSchedulerOf<DispatchQueue> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      ImmediateScheduler(now: DispatchQueue.SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  extension UIScheduler {
    /// An immediate scheduler that can substitute itself for a UI scheduler.
    public static var immediate: ImmediateSchedulerOf<UIScheduler> {
      // NB: `DispatchTime(uptimeNanoseconds: 0) == .now())`. Use `1` for consistency.
      ImmediateScheduler(now: UIScheduler.SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1)))
    }
  }

  extension OperationQueue {
    /// An immediate scheduler that can substitute itself for an operation queue.
    public static var immediate: ImmediateSchedulerOf<OperationQueue> {
      ImmediateScheduler(now: OperationQueue.SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  extension RunLoop {
    /// An immediate scheduler that can substitute itself for a run loop.
    public static var immediate: ImmediateSchedulerOf<RunLoop> {
      ImmediateScheduler(now: RunLoop.SchedulerTimeType(Date(timeIntervalSince1970: 0)))
    }
  }

  extension AnySchedulerOf<DispatchQueue> {
    /// An immediate scheduler that can substitute itself for a dispatch queue.
    public static var immediate: Self {
      DispatchQueue.immediate.eraseToAnyScheduler()
    }
  }

  extension AnySchedulerOf<OperationQueue> {
    /// An immediate scheduler that can substitute itself for an operation queue.
    public static var immediate: Self {
      OperationQueue.immediate.eraseToAnyScheduler()
    }
  }

  extension AnySchedulerOf<RunLoop> {
    /// An immediate scheduler that can substitute itself for a run loop.
    public static var immediate: Self {
      RunLoop.immediate.eraseToAnyScheduler()
    }
  }

  /// A convenience type to specify an `ImmediateScheduler` by the scheduler it wraps rather than by
  /// the time type and options type.
  public typealias ImmediateSchedulerOf<Scheduler> = ImmediateScheduler<
    Scheduler.SchedulerTimeType, Scheduler.SchedulerOptions
  > where Scheduler: Combine.Scheduler
#endif
