//
//  LandingScreenViewModel.swift
//  BlockChainWallet
//
//  Created by Rishik Kabra on 03/09/21.
//

import Foundation

class LandingScreenViewModel {
    var dataSource: [TransactionCellViewModel] = [TransactionCellViewModel]()
    init(_ data: TransactionCellViewModel) {
        // we can use screen response model if screen level data is also dynamic and fetched from API, but currently just passing in the cell view model to be used
        dataSource.append(data)
    }
}
