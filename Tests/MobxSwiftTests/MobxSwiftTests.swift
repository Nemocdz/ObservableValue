import XCTest
@testable import MobxSwift

final class MobxSwiftTests: XCTestCase {
    /// add 接口
    func testObservableValueChanged() {
        let success = Observeable(true)
        var sucesssValue = false
        let a = success.addObserver { change in
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
        }.add(to: object)
        
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
        }).add(to: bag)
        
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
        }).add(to: object)
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
        a.add(to: object)
        a.add(to: object2)
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
        o.dispose()
        
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
    
    func testBind() {
        let success = Observeable<Bool>(false)
        let object = ObserverObject()
        let observer = success.bind(to: object, \.success)
        success.update(true)
        let changeTime1 = object.changeTime
        success.update(true)
        XCTAssert(object.changeTime == changeTime1 + 1)
        observer.dispose()
        success.dropSame().bind(to: object, \.success)
        success.update(true)
        XCTAssert(object.success)
        let changeTime0 = object.changeTime
        success.update(true)
        XCTAssert(object.changeTime == changeTime0)
    }
    
    func testMap() {
        let success = Observeable<Bool>(false)
        var successValue = 1
        let a = success.map { $0 ? 1 : 0 }.addObserver { change in
            successValue = change.newValue
        }
        XCTAssert(successValue == 0)
        success.update(true)
        XCTAssert(successValue == 1)
    }
    
    func testQueue() {
        let exp = expectation(description: "queue")
        let key = DispatchSpecificKey<Void>()
        let success = Observeable<Bool>(false)
        let queue = DispatchQueue(label: "com.test.queue")
        queue.setSpecific(key: key, value: ())
        success.dispatch(on: queue).addObserver { change in
            XCTAssert(DispatchQueue.getSpecific(key: key) != nil)
        }
        queue.async {
            success.dispatch(on: queue).addObserver { change in
                XCTAssert(DispatchQueue.getSpecific(key: key) != nil)
                DispatchQueue.main.async {
                    exp.fulfill()
                }
            }
        }
        wait(for: [exp], timeout: 0.2)
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
        var success = false {
            didSet {
                changeTime += 1
            }
        }
        
        var changeTime = 0
    }
}
