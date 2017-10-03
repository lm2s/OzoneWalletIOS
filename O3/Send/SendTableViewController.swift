//
//  SendViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/11/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import NeoSwift
import Lottie
import KeychainAccess

class SendTableViewController: UITableViewController, AddressSelectDelegate, QRScanDelegate {
    var testAddress = "AJs38kijktEuM22sjfXqfjZ734RqR4H6JW"
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var assetTypeButton: UIButton!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var toAddressField: UITextField!
    var transactionCompleted: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        toAddressField.text = testAddress
        self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
        self.enableSendButton()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            if assetTypeButton.titleLabel?.text == "NEO" {
                assetTypeButton.titleLabel?.text = "GAS"
            } else {
                assetTypeButton.titleLabel?.text = "NEO"
            }
        } else if indexPath.row == 2 {
            amountField.becomeFirstResponder()
        } else if indexPath.row == 3 {
            noteTextView.becomeFirstResponder()
        }
    }

    @IBAction func sendButtonTapped() {
        let assetId = assetTypeButton.titleLabel?.text == "NEO" ? AssetId.neoAssetId : AssetId.gasAssetId
        let assetName = assetId == .neoAssetId ? "NEO" : "GAS"
        var amount = Double(amountField.text ?? "") ?? 0
        if assetId == .neoAssetId {
            amount.round()
        }
        let toAddress = toAddressField.text ?? ""
        DispatchQueue.main.async {
            let message = "Are you sure you want to send \(amount) \(assetName) to \(toAddress)"
            OzoneAlert.confirmDialog(message: message, cancelTitle: "Cancel", confirmTitle: "Confirm", didCancel: {}) {
                let keychain = Keychain(service: "network.o3.wallet")
                DispatchQueue.global().async {
                    do {
                        let password = try keychain
                            .authenticationPrompt("Authenticate to send transaction")
                            .get("ozonePrivateKey")
                        Authenticated.account?.sendAssetTransaction(asset: assetId, amount: amount, toAddress: toAddress) { completed, _ in
                            self.transactionCompleted = completed ?? false
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)

                            }
                        }
                    } catch let error {
                    }
                }
            }
        }
    }

    @IBAction func pasteTapped(_ sender: Any) {
        toAddressField.text = UIPasteboard.general.string
        enableSendButton()
    }

    @IBAction func scanTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "segueToQR", sender: nil)
    }

    func selectedAddress(_ address: String) {
        toAddressField.text = address
        enableSendButton()
    }

    func qrScanned(data: String) {
        toAddressField.text = data
        enableSendButton()
    }

    @IBAction func enableSendButton() {
        sendButton.isEnabled = toAddressField.text!.characters.count > 0 && amountField.text!.characters.count > 0
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToAddressSelect" {
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
            segue.destination.modalPresentationStyle = .custom
            segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
            guard let dest = segue.destination as? UINavigationController,
                let addressSelectVC = dest.childViewControllers[0] as? AddressSelectTableViewController else {
                fatalError("Undefined Table view behavior")
            }
            addressSelectVC.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(tappedCloseAddressSeletor(_:)))
            addressSelectVC.delegate = self
        } else if segue.identifier == "segueToQR" {
            guard let dest = segue.destination as? QRScannerController else {
                fatalError("Undefined segue behavior")
            }
            dest.delegate = self
        } else if segue.identifier == "segueToTransactionComplete" {
            guard let dest = segue.destination as? SendCompleteViewController else {
                fatalError("Undefined segue behavior")
            }
            dest.transactionSucceeded = transactionCompleted
        }
    }

    @IBAction func addressTapped(_ sender: Any) {
        performSegue(withIdentifier: "segueToAddressSelect", sender: nil)
    }

    @IBAction func tappedCloseAddressSeletor(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}