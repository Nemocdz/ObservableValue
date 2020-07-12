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
    
    func testObservaeRetain() {
        let exp = expectation(description: "retain_cycle")
        
        var object: RetainCycle? = RetainCycle {
            exp.fulfill()
        }
        
        let success = Observeable<Bool>(false)
        success.addObserver(for: object!) { object, oldValue, newValue in
        }
        
        object = nil
        wait(for: [exp], timeout: 1.0)
    }

    static var allTests = [
        ("test1", testObservableValueChanged),
        ("test2", testObservaeRetain),
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
