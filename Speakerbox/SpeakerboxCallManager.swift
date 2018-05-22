/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Manager of SpeakerboxCalls, which demonstrates using a CallKit CXCallController to request actions on calls
*/

import UIKit
import CallKit

final class SpeakerboxCallManager: NSObject {

    let callController = CXCallController() //用于与呼叫进行交互和观察的程序化界面

    // MARK: Actions

    func startCall(handle: String, video: Bool = false) {
        //可以到达呼叫接收方的方式，例如电话号码或电子邮件地址
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle) //发起呼叫行为的封装

        startCallAction.isVideo = video

        let transaction = CXTransaction() //包含零个或多个要由呼叫控制器执行的操作对象的对象
        transaction.addAction(startCallAction)

        requestTransaction(transaction)
    }

    func end(call: SpeakerboxCall) {
        let endCallAction = CXEndCallAction(call: call.uuid) //封闭了结束通话的行为
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)

        requestTransaction(transaction)
    }

    func setHeld(call: SpeakerboxCall, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold) //将通话保持或将通话移除的行为的封装
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        requestTransaction(transaction)
    }

    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction successfully")
            }
        }
    }

    // MARK: Call Management

    static let CallsChangedNotification = Notification.Name("CallManagerCallsChangedNotification") 

    private(set) var calls = [SpeakerboxCall]()

    func callWithUUID(uuid: UUID) -> SpeakerboxCall? {
        guard let index = calls.index(where: { $0.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }

    func addCall(_ call: SpeakerboxCall) {
        calls.append(call)

        call.stateDidChange = { [weak self] in
            self?.postCallsChangedNotification()
        }

        postCallsChangedNotification()
    }

    func removeCall(_ call: SpeakerboxCall) {
        calls.removeFirst(where: { $0 === call })
        postCallsChangedNotification()
    }

    func removeAllCalls() {
        calls.removeAll()
        postCallsChangedNotification()
    }

    private func postCallsChangedNotification() {
        NotificationCenter.default.post(name: type(of: self).CallsChangedNotification, object: self)
    }

    // MARK: SpeakerboxCallDelegate

    func speakerboxCallDidChangeState(_ call: SpeakerboxCall) {
        postCallsChangedNotification()
    }

}
