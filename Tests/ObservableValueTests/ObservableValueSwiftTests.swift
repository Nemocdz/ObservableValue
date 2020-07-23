import XCTest
@testable import ObservableValue

final class ObservableValueSwiftTests: XCTestCase {
    /// add 接口
    func testObservableValueChanged() {
        let success = Observable(true)
        var sucesssValue = false
        let a = success.addObserver { change in
            sucesssValue = change.newValue
        }
        XCTAssert(!sucesssValue)
        success.update(true)
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
        
        let success = Observable<Bool>(false)
        success.addObserver { change in
        }.add(to: object)
        
        object = nil
        wait(for: [exp], timeout: 1)
    }
    
    /// DisposeBag
    func testObserverRemove0() {
        let success = Observable<Bool>(false)
        var successValue = false
        let bag = DisposeBag()
        
        success.addObserver(handler: { change in
            successValue = change.newValue
        }).add(to: bag)
        
        bag.disposeAll()
        
        success.update(true)
        XCTAssert(!successValue)
    }
        
    /// store 在其他 object 中
    func testObserverRemove1() {
        let success = Observable<Bool>(false)
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
        let success = Observable<Bool>(true)
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
        let success = Observable<Bool>(false)
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
        
        var success: Observable<Bool>? = Observable<Bool>(false)
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
        let success = Observable<Bool>(false)
        var successValue = false
        success.addObserver { change in
            successValue = change.newValue
        }
        success.removeObservers()
        success.update(true)
        XCTAssert(!successValue)
    }
    
    func testBind() {
        let success = Observable<Bool>(false)
        let object = ObserverObject()
        let observer = success.bind(to: object, at: \.success)
        success.update(true)
        let changeTime1 = object.changeTime
        success.update(true)
        XCTAssert(object.changeTime == changeTime1 + 1)
        observer.dispose()
        success.dropSame().bind(to: object, at: \.success)
        success.update(true)
        XCTAssert(object.success)
        let changeTime0 = object.changeTime
        success.update(true)
        XCTAssert(object.changeTime == changeTime0)
    }
    
    func testMap() {
        let success = Observable<Bool>(false)
        var successValue = 0
        let a = success.map { $0 ? 1 : 0 }.addObserver { change in
            successValue = change.newValue
        }
        success.update(true)
        XCTAssert(successValue == 1)
    }
    
    func testQueue() {
        let exp = expectation(description: "queue")
        let key = DispatchSpecificKey<Void>()
        let success = Observable<Bool>(false)
        let queue = DispatchQueue(label: "com.test.queue")
        queue.setSpecific(key: key, value: ())
        let a = success.dispatch(on: queue).addObserver { change in
            XCTAssert(DispatchQueue.getSpecific(key: key) != nil)
        }
        success.update(true)
        queue.async {
            let b = success.dispatch(on: queue).addObserver { change in
                XCTAssert(DispatchQueue.getSpecific(key: key) != nil)
                DispatchQueue.main.async {
                    exp.fulfill()
                }
            }
            success.update(true)
        }
        wait(for: [exp], timeout: 0.2)
    }
    
    func testDropNil() {
        let success = Observable<Bool?>(false)
        var successValue: Bool? = nil
        let a = success.dropNil(value: false).addObserver { change in
            successValue = change.newValue
        }
        XCTAssertNil(successValue)
        success.update(false)
        XCTAssert(!(successValue!))
        success.update(true)
        XCTAssert(successValue!)
        success.update(nil)
        XCTAssert(successValue!)
    }
    
    func testBind2() {
        let o1 = Observable<Int>(1)
        let o2 = Observable<Int?>(2)
        let o = ObserverObject()
        /// wrapped to wrapped
        o1.bind(to: o, at: \.value)
        XCTAssert(o.value == 1)
        /// wrapped to optional
        o1.bind(to: o, at: \.value2)
        XCTAssert(o.value2 == 1)
        /// optional to wrapped
        o2.bind(to: o, at: \.value)
        XCTAssert(o.value == 2)
        /// optional to optional
        o2.bind(to: o, at: \.value2)
        XCTAssert(o.value2 == 2)
        o1.update(3)
        XCTAssert(o.value == 3)
        XCTAssert(o.value2 == 3)
        o2.update(4)
        XCTAssert(o.value == 4)
        XCTAssert(o.value2 == 4)
    }

    static var allTests = [
        ("test1", testObservableValueChanged),
    ]
}

extension ObservableValueSwiftTests {
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
        
        var value: Int = 0
        var value2: Int? = 0
    }
}
