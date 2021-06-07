import Foundation

final class CallStation {
    private var userSet = Set<User>()
    private var callStore = [CallID: Call]()
    private var currentCallsStore = [UUID: Call]()
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CallStation: Station {
    func users() -> [User] {
        return Array(userSet)
    }
    
    func add(user: User) {
        if !userSet.contains(user) {
            userSet.update(with: user)
        }
    }
    
    func remove(user: User) {
        userSet.remove(user)
        if let call = currentCall(user: user) {
            let theCall = Call(id: call.id, incomingUser: call.incomingUser, outgoingUser: call.outgoingUser, status: .ended(reason: .error))
            currentCallsStore[call.incomingUser.id] = nil
            currentCallsStore[call.outgoingUser.id] = nil
            callStore[call.id] = theCall
        }
    }
    
    func execute(action: CallAction) -> CallID? {
        switch action {
        case let CallAction.start(from: user1, to: user2):
            if userSet.contains(user1) {
                if !userSet.contains(user2) {
                    let call = Call(id: UUID(), incomingUser: user2, outgoingUser: user1, status: .ended(reason: .error))
                    callStore[call.id] = call
                    return call.id
                }
                if currentCall(user: user1) != nil || currentCall(user: user2) != nil {
                    let call = Call(id: UUID(), incomingUser: user2, outgoingUser: user1, status: .ended(reason: .userBusy))
                    callStore[call.id] = call
                    return call.id
                }
                let call = Call(id: UUID(), incomingUser: user2, outgoingUser: user1, status: .calling)
                callStore[call.id] = call
                currentCallsStore[user1.id] = call
                currentCallsStore[user2.id] = call
                return call.id
            }
        case let .answer(from: user1):
            if let call = currentCallsStore[user1.id], call.status == .calling, call.incomingUser == user1 {
                let theCall = Call(id: call.id, incomingUser: call.incomingUser, outgoingUser: call.outgoingUser, status: .talk)
                callStore[call.id] = theCall
                currentCallsStore[call.incomingUser.id] = theCall
                currentCallsStore[call.outgoingUser.id] = theCall
                return theCall.id
            }
           
        case let .end(from: user1):
            if let call = currentCallsStore[user1.id] {
                currentCallsStore[call.outgoingUser.id] = nil
                currentCallsStore[call.incomingUser.id] = nil
                let status: CallStatus = (call.status == .talk) ? .ended(reason: .end): .ended(reason: .cancel)
                let theCall = Call(id: call.id, incomingUser: call.incomingUser, outgoingUser: call.outgoingUser, status: status)
                callStore[call.id] = theCall
                return theCall.id
            }
        }
        return nil

    }
    
    func calls() -> [Call] {
        return Array(callStore.values)
    }
    
    func calls(user: User) -> [Call] {
        return calls().filter{
            $0.incomingUser == user || $0.outgoingUser == user
        }
    }
    
    func call(id: CallID) -> Call? {
        return callStore[id]
    }
    
    func currentCall(user: User) -> Call? {
        return currentCallsStore[user.id]
    }
}
