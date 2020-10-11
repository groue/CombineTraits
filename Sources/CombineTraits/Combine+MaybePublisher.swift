import Combine

extension Publishers.AllSatisfy: MaybePublisher { }

extension Publishers.AssertNoFailure: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Autoconnect: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Breakpoint: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Catch: MaybePublisher
where Upstream: MaybePublisher, NewPublisher: MaybePublisher { }

extension Publishers.Collect: MaybePublisher { }

extension Publishers.CombineLatest: MaybePublisher
where A: MaybePublisher, B: MaybePublisher { }

extension Publishers.CombineLatest3: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher { }

extension Publishers.CombineLatest4: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher, D: MaybePublisher { }

extension Publishers.CompactMap: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Contains: MaybePublisher { }

extension Publishers.ContainsWhere: MaybePublisher { }

extension Publishers.Count: MaybePublisher { }

extension Publishers.Decode: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Delay: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Encode: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Filter: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.First: MaybePublisher { }

extension Publishers.FirstWhere: MaybePublisher { }

extension Publishers.FlatMap: MaybePublisher
where Upstream: MaybePublisher, NewPublisher: MaybePublisher { }

extension Publishers.HandleEvents: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.IgnoreOutput: MaybePublisher { }

extension Publishers.Last: MaybePublisher { }

extension Publishers.LastWhere: MaybePublisher { }

extension Publishers.MakeConnectable: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Map: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.MapError: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.MapKeyPath: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.MapKeyPath2: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.MapKeyPath3: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Print: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.ReceiveOn: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Reduce: MaybePublisher { }

extension Publishers.ReplaceEmpty: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.ReplaceError: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Retry: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.SetFailureType: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.Share: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.SubscribeOn: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.SwitchToLatest: MaybePublisher
where Upstream: MaybePublisher, P: MaybePublisher { }

extension Publishers.Timeout: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.TryAllSatisfy: MaybePublisher { }

extension Publishers.TryCatch: MaybePublisher
where Upstream: MaybePublisher, NewPublisher: MaybePublisher { }

extension Publishers.TryCompactMap: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.TryContainsWhere: MaybePublisher { }

extension Publishers.TryFilter: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.TryFirstWhere: MaybePublisher { }

extension Publishers.TryLastWhere: MaybePublisher { }

extension Publishers.TryMap: MaybePublisher
where Upstream: MaybePublisher { }

extension Publishers.TryReduce: MaybePublisher { }

// We can't declare "OR" conformance (Zip is a maybe if A or B is a maybe)
extension Publishers.Zip: MaybePublisher
where A: MaybePublisher, B: MaybePublisher { }

// We can't declare "OR" conformance (Zip3 is a maybe if A or B or C is a maybe)
extension Publishers.Zip3: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher { }

// We can't declare "OR" conformance (Zip4 is a maybe if A or B or C or D is a maybe)
extension Publishers.Zip4: MaybePublisher
where A: MaybePublisher, B: MaybePublisher, C: MaybePublisher, D: MaybePublisher { }

extension Result.Publisher: MaybePublisher { }

extension AnyPublisher: MaybePublisher
where Output == Never { }

extension Deferred: MaybePublisher
where DeferredPublisher: MaybePublisher { }

extension Empty: MaybePublisher { }

extension Fail: MaybePublisher { }

extension Future: MaybePublisher { }

extension Just: MaybePublisher { }
