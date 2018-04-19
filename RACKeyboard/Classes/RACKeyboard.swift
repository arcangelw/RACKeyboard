//
//  RACKeyboard.swift
//  FBSnapshotTestCase
//
//  Created by 吴哲 on 2018/4/19.
//

#if os(iOS)
import UIKit

import ReactiveCocoa
import ReactiveSwift
import Result

public protocol RACKeyboardType {
    var frame:Property<CGRect> {get}
    var visibleHeight: Property<CGFloat> { get }
    var willShowVisibleHeight: Property<CGFloat> { get }
    var isHidden: Property<Bool> { get }
}

public class RACKeyboard: NSObject, RACKeyboardType {
    
    public static let shared = RACKeyboard()
    
    public var frame: Property<CGRect>
    
    public var visibleHeight: Property<CGFloat>
    
    public var willShowVisibleHeight: Property<CGFloat>
    
    public var isHidden: Property<Bool>
    

    fileprivate let panRecognizer = UIPanGestureRecognizer()
    
    override init() {
        let defaultFrame = CGRect(
            x: 0.0,
            y: UIScreen.main.bounds.height,
            width: UIScreen.main.bounds.width,
            height: 0.0
        )
        let frameVariable = MutableProperty<CGRect>(defaultFrame)
        self.frame = Property<CGRect>(frameVariable).skipRepeats()
        self.visibleHeight = self.frame.map({UIScreen.main.bounds.height - $0.origin.y})
        let willShowVisibleHeightProducer = self.visibleHeight.producer
            .scan((visibleHeight : 0.0 , isShowing : false), { (lastState, newVisibleHeight) in
            return (visibleHeight : newVisibleHeight, isShowing:lastState.visibleHeight == 0.0 && newVisibleHeight > 0.0 ) })
            .filter({$0.isShowing}).map({$0.visibleHeight})
        self.willShowVisibleHeight = Property<CGFloat>(initial: 0.0, then: willShowVisibleHeightProducer)
        self.isHidden = self.visibleHeight.map({$0 == 0.0}).skipRepeats()
        super.init()
        
        // keyboard will change frame
        let willChangeFrame = NotificationCenter.default.reactive.notifications(forName: .UIKeyboardWillChangeFrame)
            .map({ notification -> CGRect  in
            let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
            return rectValue?.cgRectValue ?? defaultFrame
            })
            .map({ frame -> CGRect in
                if frame.origin.y < 0.0 {// if went to wrong frame
                    var newFrame = frame
                    newFrame.origin.y = UIScreen.main.bounds.height - newFrame.height
                    return newFrame
                }
                return frame
            })
        
        // keyboard will hide
        let willHiden = NotificationCenter.default.reactive.notifications(forName: .UIKeyboardWillHide)
            .map({ notification -> CGRect  in
                let rectValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
                return rectValue?.cgRectValue ?? defaultFrame
            })
            .map({ frame -> CGRect in
                if frame.origin.y < 0.0 {// if went to wrong frame
                    var newFrame = frame
                    newFrame.origin.y = UIScreen.main.bounds.height
                    return newFrame
                }
                return frame
            })
        
        // pan gesture
        func flatMap(value:(UIPanGestureRecognizer, CGRect)) -> SignalProducer<CGRect, NoError>{
            guard case .changed = value.0.state,
              let window = UIApplication.shared.windows.first,
              value.1.origin.y < UIScreen.main.bounds.height
            else {return SignalProducer<CGRect, NoError>.empty}
            let origin = value.0.location(in: window)
            var newFrame = value.1
            newFrame.origin.y = max(origin.y, UIScreen.main.bounds.height - value.1.height)
            return SignalProducer<CGRect, NoError>(value: newFrame)
        }
        let didPan = self.panRecognizer.reactive.stateChanged
            .withLatest(from: frameVariable.signal)
            .flatMap(.latest){flatMap(value: $0)}
        
        //merge into single
        Signal.merge([willChangeFrame,willHiden,didPan]).take(during: reactive.lifetime).producer.startWithValues({frameVariable.value = $0})
        
        // panRecognizer
        self.panRecognizer.delegate = self
   
        SignalProducer(value: Void()).concat(NotificationCenter.default.reactive.notifications(forName: .UIApplicationDidFinishLaunching)
            .map({_ in Void()}).producer)
            .take(during: reactive.lifetime)
            .startWithValues { _ in
                UIApplication.shared.windows.first?.addGestureRecognizer(self.panRecognizer)
            }
    

    }
}

// MARK: - UIGestureRecognizerDelegate
extension RACKeyboard: UIGestureRecognizerDelegate{
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: gestureRecognizer.view)
        var view = gestureRecognizer.view?.hitTest(point, with: nil)
        while let candidate = view {
            if let scrollView = candidate as? UIScrollView,
                case .interactive = scrollView.keyboardDismissMode {
                return true
            }
            view = candidate.superview
        }
        return false
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return gestureRecognizer === self.panRecognizer
    }
}

#endif
