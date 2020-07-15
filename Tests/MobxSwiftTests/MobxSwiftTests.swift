import XCTest
@testable import MobxSwift

final class MobxSwiftTests: XCTestCase {
    func testObservableValueChanged() {
        let success = Observeable<Bool>(false)
        XCTAssert(!success.value)
        let object = ObserverObject()
        success.addObserver(for: object) { object, change in
            object.success = change.newValue
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
        success.addObserver(for: object!) { object, change in
        }
        
        object = nil
        wait(for: [exp], timeout: 1)
    }
    
    func testObserverRemove0() {
        let exp = expectation(description: "remove_0")
        
        let success = Observeable<Bool>(false)
        var successValue = false
        var c = [AnyObserver]()
        success.addObserver(handler: { change in
            successValue = change.newValue
        }).store(in: &c)
        c.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            success.update(true)
            XCTAssert(!successValue)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.1)
    }
    
    func testObserverRemove1() {
        let exp = expectation(description: "remove_1")
        
        let success = Observeable<Bool>(false)
        var successValue = false
        
        var object: AnyObject? = NSObject()
        success.addObserver(handler: { change in
            successValue = change.newValue
        }).store(in: object)
        object = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            success.update(true)
            XCTAssert(!successValue)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.1)
    }
    
    func testObserverRemove2() {
        let exp = expectation(description: "remove_2")
        
        let success = Observeable<Bool>(false)
        var successValue = false
        var c = [AnyObserver]()
        var object: AnyObject? = NSObject()
        success.addObserver(handler: { change in
            successValue = change.newValue
        }).store(in: &c).store(in: object)
        object = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            success.update(true)
            XCTAssert(!successValue)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.1)
    }
    
    func testObserverRemove3() {
        let exp = expectation(description: "remove_3")
        
        let success = Observeable<Bool>(false)
        var successValue = false
        let o = success.addObserver(handler: { change in
            successValue = change.newValue
        })
        o.remove()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            success.update(true)
            XCTAssert(!successValue)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.1)
    }
    
    func testObserverRemove4() {
        let exp = expectation(description: "remove_4")
        
        var success: Observeable<Bool>? = Observeable<Bool>(false)
        weak var a = success!.addObserver { change in
        }
        success = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(a == nil)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.1)
    }
    
    func testObservableValueChanged2() {
        let success = Observeable(true)
        var sucesssValue = false
        success.addObserver { change in
            sucesssValue = change.newValue
        }
        XCTAssert(sucesssValue)
        success.update(false)
        XCTAssert(!sucesssValue)
    }

    static var allTests = [
        ("test1", testObservableValueChanged),
        ("test2", testObservableRetain),
        //("test3", testObserverRemove),
        ("test4", testObservableValueChanged2),
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
