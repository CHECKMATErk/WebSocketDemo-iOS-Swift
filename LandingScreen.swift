//
//  ViewController.swift
//  BlockChainWallet
//
//  Created by Rishik Kabra on 03/09/21.
//

import UIKit
import Combine



protocol WebSocketConnectionDelegate {
    func onConnected(connection: WebSocketConnection)
    func onDisconnected(connection: WebSocketConnection, error: Error?)
    func onError(connection: WebSocketConnection, error: Error)
    func onMessage(connection: WebSocketConnection, text: String)
    func onMessage(connection: WebSocketConnection, data: Data)
}

class LandingScreen: UIViewController {
    
    @IBOutlet weak var transactionHistoryTableView: UITableView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    //var socketConnection = NetworkHelper(withSocketURL: URL(string: "wss://ws.blockchain.info/inv")!)
    var viewModel: [TransactionCellViewModel] = [TransactionCellViewModel]()
    //LandingScreenViewModel would contain a datasource array that would continue to change
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.navigationController?.title = "Transaction History"
        self.transactionHistoryTableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
        self.clearButton.layer.cornerRadius = 12
        self.transactionHistoryTableView.isHidden = true
        self.clearButton.isHidden = true
        self.loadingActivityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now()+4) {
            self.initializeWebsocket()
        }
    }
    
    func setUpViewModel(_ data: TransactionCellViewModel){
        if self.viewModel.count>=5 {
            self.viewModel.remove(at: 0)
        }
        self.viewModel.append(data)
        DispatchQueue.main.async {
            // we can use asyncAfter method to keep transactions for readability and maintain a separate array of all transactions and take 5 of them out at a time in a fixed interval say every 10 seconds.
            // the current solution works for realtime updates
            if self.viewModel.count >= 5{
                self.transactionHistoryTableView.reloadData()
                self.loadingView.isHidden = true
                self.loadingActivityIndicator.stopAnimating()
                self.transactionHistoryTableView.isHidden = false
                self.clearButton.isHidden = false
                
            }
        }
        
    }
    
    func setupTableView() {
        self.transactionHistoryTableView.separatorStyle = .none
        self.transactionHistoryTableView.estimatedRowHeight = UITableView.automaticDimension
        //self.transactionHistoryTableView.rowHeight = UITableView.automaticDimension
        self.transactionHistoryTableView.tableFooterView = UIView(frame: .zero)
        self.transactionHistoryTableView.delegate = self
        self.transactionHistoryTableView.dataSource = self
    }
    
    @IBAction func clearClicked(_ sender: Any) {
        self.viewModel.removeAll()
        
       // show loader
        self.transactionHistoryTableView.isHidden = true
        self.clearButton.isHidden = true
        self.loadingView.isHidden = false
        self.loadingActivityIndicator.startAnimating()
      // remove all cells
        self.transactionHistoryTableView.reloadData()
    }
}

extension LandingScreen: UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return viewmodel rows.count if we limit appending at network level or return 5
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < 5 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell", for: indexPath) as! TransactionTableViewCell
            // after setting data in setupViewModel post data receival from socket uncomment these lines
            if viewModel.count>0{
                cell.configureCell(model: viewModel[indexPath.row])
            }
            return cell
        }
        return UITableViewCell()
    }
    
    
}

extension LandingScreen: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240
    }
    
}

extension LandingScreen{
    func initializeWebsocket(){
        if let url = URL(string: "wss://ws.blockchain.info/inv"){
            var socketConnection = NetworkHelper(withSocketURL: url)
            self.setupConnection(socketConnection: socketConnection)
            let requestForTransactions: [String: String] = ["op":"unconfirmed_sub"]
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(requestForTransactions) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    socketConnection.send(message: jsonString)
                }
            }
        }
        
    }
    
    func setupConnection(socketConnection: NetworkHelper){
        socketConnection.establishConnection()
        
        socketConnection.didReceiveMessage = { message in
            print(message)
            do {
                let data = Data(message.utf8)
                let dataModel = try JSONDecoder().decode(TransactionCellWidgetModel.self, from: data)
                let viewModel = TransactionCellViewModel.init(dataModel)
                if let amount = viewModel.transactionAmount {
                    if amount > 100 {
                        self.setUpViewModel(viewModel)
                    }
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
        
        socketConnection.didReceiveError = { error in
            //Handle error here
        }
        
        socketConnection.didOpenConnection = {
            //Connection opened
        }
        
        socketConnection.didCloseConnection = {
            // Connection closed
        }
        
        socketConnection.didReceiveData = { data in
            // receive Data
        }
    }
}

