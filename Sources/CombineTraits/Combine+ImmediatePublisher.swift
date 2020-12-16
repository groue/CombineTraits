import Combine

extension Publishers.AssertNoFailure: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Breakpoint: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Catch: ImmediatePublisher
where Upstream: ImmediatePublisher, NewPublisher: ImmediatePublisher { }

extension Publishers.CombineLatest: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher { }

extension Publishers.CombineLatest3: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher { }

extension Publishers.CombineLatest4: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher { }

extension Publishers.Concatenate: ImmediatePublisher
where Prefix: ImmediatePublisher { }

extension Publishers.Decode: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Encode: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.First: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.FlatMap: ImmediatePublisher
where Upstream: ImmediatePublisher, NewPublisher: ImmediatePublisher { }

extension Publishers.HandleEvents: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Map: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.MapError: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.MapKeyPath: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.MapKeyPath2: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.MapKeyPath3: ImmediatePublisher
where Upstream: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge3: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge4: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge5: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher, E: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge6: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher, E: ImmediatePublisher, F: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge7: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher, E: ImmediatePublisher, F: ImmediatePublisher, G: ImmediatePublisher { }

// We can't declare "OR" conformance (Merge is immediate if any upstream publisher is immediate)
extension Publishers.Merge8: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher, E: ImmediatePublisher, F: ImmediatePublisher, G: ImmediatePublisher, H: ImmediatePublisher { }

extension Publishers.MergeMany: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Print: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.RemoveDuplicates: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.ReplaceEmpty: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.ReplaceError: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Retry: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Scan: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.SetFailureType: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.SwitchToLatest: ImmediatePublisher
where P: ImmediatePublisher, Upstream: ImmediatePublisher { }

extension Publishers.TryCatch: ImmediatePublisher
where Upstream: ImmediatePublisher, NewPublisher: ImmediatePublisher { }

extension Publishers.TryMap: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.TryRemoveDuplicates: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.TryScan: ImmediatePublisher
where Upstream: ImmediatePublisher { }

extension Publishers.Zip: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher { }

extension Publishers.Zip3: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher { }

extension Publishers.Zip4: ImmediatePublisher
where A: ImmediatePublisher, B: ImmediatePublisher, C: ImmediatePublisher, D: ImmediatePublisher { }

extension Result.Publisher: ImmediatePublisher { }

extension CurrentValueSubject: ImmediatePublisher { }

extension Deferred: ImmediatePublisher
where DeferredPublisher: ImmediatePublisher { }

extension Fail: ImmediatePublisher { }

extension Just: ImmediatePublisher { }

extension Record: ImmediatePublisher { }
