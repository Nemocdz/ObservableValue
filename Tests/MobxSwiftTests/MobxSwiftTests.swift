import XCTest
@testable import MobxSwift

final class MobxSwiftTests: XCTestCase {
    func testObservableValueChanged() {
        let success = Observeable<Bool>(false)
        XCTAssert(!success.value)
        let object = ObserverObject()
        success.addObserver(for: object) { object, oldValue, newValue in
            object.success = newValue
        }
        XCTAssert(!object.success)
        success.update(true)
        XCTAssert(object.success)
    }
    
    func testObservableRetain() {
        let exp = expectation(description: "retain_cycle_1")
        var object: RetainCycle? = RetainCycle {
            exp.fulfill()
        }
        
        let success = Observeable<Bool>(false)
        success.addObserver(for: object!) { object, oldValue, newValue in
        }
        
        object = nil
        wait(for: [exp], timeout: 1.0)
    }
    
    func testObserverRemove() {
        var success: Observeable<Bool>? = Observeable<Bool>(false)
        let object = ObserverObject()
        let observer = success!.addObserver(for: object) { object, oldValue, newValue in
        }
        XCTAssert(observer.remove())
        XCTAssert(!observer.remove())
        let observer2 = success!.addObserver(for: object) { object, oldValue, newValue in
        }
        success = nil
        XCTAssert(!observer2.remove())
    }

    static var allTests = [
        ("test1", testObservableValueChanged),
        ("test2", testObservableRetain),
        ("test3", testObserverRemove),
    ]
}

extension MobxSwiftTests {
    class RetainCycle {
        let deinitHandler: () -> ()
        
        init(_ deinitHandler: @escaping () -> ()) {
            self.deinitHandler = deinitHandler
        }
        
        deinit {
            deinitHandler()
        }
    }
    
    class ObserverObject {
        var success = false
    }
}
