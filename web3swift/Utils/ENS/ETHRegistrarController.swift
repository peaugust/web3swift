//
//  RegistrarController.swift
//  web3swift
//
//  Created by Anton on 15/04/2019.
//  Copyright © 2019 The Matter Inc. All rights reserved.
//

import Foundation
import BigInt
import EthereumAddress

public extension ENS {
    class ETHRegistrarController {
        let web3: web3
        let address: EthereumAddress
        
        lazy var contract: web3.web3contract = {
            let contract = self.web3.contract(Web3.Utils.ethRegistrarControllerABI, at: self.address, abiVersion: 2)
            precondition(contract != nil)
            return contract!
        }()
        
        lazy var defaultOptions: TransactionOptions = {
            return TransactionOptions.defaultOptions
        }()
        
        init(web3: web3, address: EthereumAddress) {
            self.web3 = web3
            self.address = address
        }
        
        public func getRentPrice(name: String, duration: UInt) throws -> UInt {
            guard let transaction = self.contract.read("rentPrice", parameters: [name, duration] as [AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            guard let result = try? transaction.call(transactionOptions: defaultOptions) else {throw Web3Error.processingError(desc: "Can't call transaction")}
            guard let price = result["0"] as? UInt else {throw Web3Error.processingError(desc: "Can't get answer")}
            return price
        }
        
        public func checkNameValidity(name: String) throws -> Bool {
            guard let transaction = self.contract.read("valid", parameters: [name] as [AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            guard let result = try? transaction.call(transactionOptions: defaultOptions) else {throw Web3Error.processingError(desc: "Can't call transaction")}
            guard let valid = result["0"] as? Bool else {throw Web3Error.processingError(desc: "Can't get answer")}
            return valid
        }
        
        public func isNameAvailable(name: String) throws -> Bool {
            guard let transaction = self.contract.read("available", parameters: [name as AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            guard let result = try? transaction.call(transactionOptions: defaultOptions) else {throw Web3Error.processingError(desc: "Can't call transaction")}
            guard let available = result["0"] as? Bool else {throw Web3Error.processingError(desc: "Can't get answer")}
            return available
        }
        
        public func calculateCommitmentHash(name: String, owner: EthereumAddress, secret: [UInt32]) throws -> [UInt32] {
            guard let transaction = self.contract.read("makeCommitment", parameters: [name, owner, secret] as [AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            guard let result = try? transaction.call(transactionOptions: defaultOptions) else {throw Web3Error.processingError(desc: "Can't call transaction")}
            guard let hash = result["0"] as? [UInt32] else {throw Web3Error.processingError(desc: "Can't get answer")}
            return hash
        }
        
        public func sumbitCommitment(from: EthereumAddress, commitment: [UInt32]) throws -> WriteTransaction {
            defaultOptions.from = from
            defaultOptions.to = self.address
            guard let transaction = self.contract.write("commit", parameters: [commitment as AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            return transaction
        }
        
        public func registerName(from: EthereumAddress, name: String, owner: EthereumAddress, duration: UInt32, secret: [UInt32], price: String) throws -> WriteTransaction {
            guard let amount = Web3.Utils.parseToBigUInt(price, units: .eth) else {throw Web3Error.inputError(desc: "Wrong price: no way for parsing to ether units")}
            defaultOptions.value = amount
            defaultOptions.from = from
            defaultOptions.to = self.address
            guard let transaction = self.contract.write("register", parameters: [name, owner, duration, secret] as [AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            return transaction
        }
        
        public func extendNameRegistration(from: EthereumAddress, name: String, duration: UInt32, price: String) throws -> WriteTransaction {
            guard let amount = Web3.Utils.parseToBigUInt(price, units: .eth) else {throw Web3Error.inputError(desc: "Wrong price: no way for parsing to ether units")}
            defaultOptions.value = amount
            defaultOptions.from = from
            defaultOptions.to = self.address
            guard let transaction = self.contract.write("renew", parameters: [name, duration] as [AnyObject], extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            return transaction
        }
        
        @available(*, message: "Available for only owner")
        public func withdraw(from: EthereumAddress) throws -> WriteTransaction {
            defaultOptions.from = from
            defaultOptions.to = self.address
            guard let transaction = self.contract.write("withdraw", parameters: [AnyObject](), extraData: Data(), transactionOptions: defaultOptions) else {throw Web3Error.transactionSerializationError}
            return transaction
        }
    }
}
