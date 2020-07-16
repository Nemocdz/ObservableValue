import XCTest
@testable import MobxSwift

final class MobxSwiftTests: XCTestCase {
    /// add 接口
    func testObservableValueChanged() {
        let success = Observeable(true)
        var sucesssValue = false
        success.addObserver { change in
            sucesssValue = change.newValue
        }
        XCTAssert(sucesssValue)
        success.update(false)
        XCTAssert(!sucesssValue)
    }
    
    /// 循环引用
    func testObservableRetain() {
        let exp = expectation(description: "retain_cycle_0")
        var object: RetainCycle? = RetainCycle {
            exp.fulfill()
        }
        
        let success = Observeable<Bool>(false)
        success.addObserver { change in
        }.store(in: object)
        
        object = nil
        wait(for: [exp], timeout: 1)
    }
    
    /// DisposeBag
    func testObserverRemove0() {
        let success = Observeable<Bool>(false)
        var successValue = false
        let bag = DisposeBag()
        
        success.addObserver(handler: { change in
            successValue = change.newValue
        }).store(in: bag)
        
        bag.stop()
        
        success.update(true)
        XCTAssert(!successValue)
    }
        
    /// store 在其他 object 中
    func testObserverRemove1() {
        let success = Observeable<Bool>(false)
        var successValue = false
        
        var object: AnyObject? = NSObject()
        success.addObserver(handler: { change in
            successValue = change.newValue
        }).store(in: object)
        object = nil
        
        success.update(true)
        XCTAssert(!successValue)
    }
    
    /// 覆盖 store
    func testObserverRemove2() {
        let success = Observeable<Bool>(true)
        var successValue = false
        var object: AnyObject? = NSObject()
        var object2: AnyObject? = NSObject()
        let a = success.addObserver { change in
            successValue = change.newValue
        }
        a.store(in: object)
        a.store(in: object2)
        object = nil
        
        success.update(true)
        XCTAssert(successValue)
        object2 = nil
        success.update(false)
        XCTAssert(successValue)
    }
    
    /// 手动 remove
    func testObserverRemove3() {
        let success = Observeable<Bool>(false)
        var successValue = false
        let o = success.addObserver(handler: { change in
            successValue = change.newValue
        })
        o.stop()
        
        success.update(true)
        XCTAssert(!successValue)
    }
    
    /// 检查释放
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
    
    
    func testObserverRemove5() {
        let success = Observeable<Bool>(false)
        var successValue = false
        success.addObserver { change in
            successValue = change.newValue
        }
        success.removeObservers()
        success.update(true)
        XCTAssert(!successValue)
    }

    static var allTests = [
        ("test1", testObservableValueChanged),
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
