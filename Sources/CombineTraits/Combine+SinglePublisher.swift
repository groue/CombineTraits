import Combine

extension Publishers.AllSatisfy: SinglePublisher { }

extension Publishers.AssertNoFailure: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Autoconnect: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Breakpoint: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Catch: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

extension Publishers.Collect: SinglePublisher { }

extension Publishers.CombineLatest: SinglePublisher
where A: SinglePublisher, B: SinglePublisher { }

extension Publishers.CombineLatest3: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher { }

extension Publishers.CombineLatest4: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher, D: SinglePublisher { }

extension Publishers.Contains: SinglePublisher { }

extension Publishers.ContainsWhere: SinglePublisher { }

extension Publishers.Count: SinglePublisher { }

extension Publishers.Decode: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Delay: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Encode: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.FlatMap: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

extension Publishers.HandleEvents: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MakeConnectable: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Map: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapError: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapKeyPath: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapKeyPath2: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.MapKeyPath3: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Print: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.ReceiveOn: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Reduce: SinglePublisher { }

extension Publishers.ReplaceEmpty: SinglePublisher
where Upstream: MaybePublisher { }

extension Publishers.ReplaceError: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Retry: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.SetFailureType: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.Share: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.SubscribeOn: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.SwitchToLatest: SinglePublisher
where Upstream: SinglePublisher, P: SinglePublisher { }

extension Publishers.Timeout: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.TryAllSatisfy: SinglePublisher { }

extension Publishers.TryCatch: SinglePublisher
where Upstream: SinglePublisher, NewPublisher: SinglePublisher { }

extension Publishers.TryContainsWhere: SinglePublisher { }

extension Publishers.TryMap: SinglePublisher
where Upstream: SinglePublisher { }

extension Publishers.TryReduce: SinglePublisher { }

// We can't declare "OR" conformance (Zip is a maybe if A or B is a maybe)
extension Publishers.Zip: SinglePublisher
where A: SinglePublisher, B: SinglePublisher { }

// We can't declare "OR" conformance (Zip3 is a maybe if A or B or C is a maybe)
extension Publishers.Zip3: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher { }

// We can't declare "OR" conformance (Zip4 is a maybe if A or B or C or D is a maybe)
extension Publishers.Zip4: SinglePublisher
where A: SinglePublisher, B: SinglePublisher, C: SinglePublisher, D: SinglePublisher { }

extension Result.Publisher: SinglePublisher { }

extension Deferred: SinglePublisher
where DeferredPublisher: SinglePublisher { }

extension Fail: SinglePublisher { }

extension Future: SinglePublisher { }

extension Just: SinglePublisher { }
