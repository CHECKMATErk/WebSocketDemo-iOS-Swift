//
//  NetworkHelper.swift
//  BlockChainWallet
//
//  Created by Rishik Kabra on 03/09/21.
//

import Foundation
import Starscream

protocol WebSocketProtocol {
    func send(message : String)
    func send(data : Data)
    func establishConnection()
    func disconnect()
}

class NetworkHelper: NSObject{
    
    var didOpenConnection : (()->())?
    var didCloseConnection : (()->())?
    var didReceiveMessage : ((_ message : String)->())?
    var didReceiveData : ((_ message : Data)->())?
    var didReceiveError : ((_ error : Error)->())?

    
    
    var urlSession : URLSession!
    var operationQueue : OperationQueue = OperationQueue()
    var socket : URLSessionWebSocketTask!
    
    
    init(withSocketURL url : URL){
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: operationQueue)
        socket = urlSession.webSocketTask(with: url)
        
    }
    
    private func addListener(){
        
        socket.receive {[weak self] (result) in
            switch result {
            case .success(let response):
                switch response {
                    
                case .data(let data):
                    self?.didReceiveData?(data)

                case .string(let message):
                    self?.didReceiveMessage?(message)
                }
            case .failure(let error):
                self?.didReceiveError?(error)
            }
            self?.addListener()

        }
    }
}

extension NetworkHelper : WebSocketProtocol {
    
    func establishConnection(){
        socket.resume()
        addListener()
        print("Establishing Connection...")
    }
    
    func disconnect(){
        socket.cancel(with: .goingAway, reason: nil)
        print("Disconnecting Connection...")
    }
    
    
    func send(message: String) {
        socket.send(URLSessionWebSocketTask.Message.string(message)) {[weak self] (error) in
            if let error = error {
                self?.didReceiveError?(error)
            }
        }
    }
    
    func send(data: Data) {
        socket.send(URLSessionWebSocketTask.Message.data(data)) {[weak self] (error) in
            if let error = error {
                self?.didReceiveError?(error)
            }
        }
    }
    
}

extension NetworkHelper : URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        didOpenConnection?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        didCloseConnection?()
    }
}

