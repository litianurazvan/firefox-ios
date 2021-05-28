//
//  AlertControllerView.swift
//  CredentialProvider
//
//  Created by razvan.litianu on 28.05.2021.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

protocol AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style,
                                barButtonItem: UIBarButtonItem?)
}

class AlertActionButtonConfiguration {
    let title: String
    let tapAction: (() -> Void)
    let style: UIAlertAction.Style
    let checked: Bool
    
    init(title: String, tapAction: @escaping () -> Void, style: UIAlertAction.Style, checked: Bool = false) {
        self.title = title
        self.tapAction = tapAction
        self.style = style
        self.checked = checked
    }
}

extension UIViewController: AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style,
                                barButtonItem: UIBarButtonItem?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        if let barButtonItem = barButtonItem {
            let presentationController = alertController.popoverPresentationController
            presentationController?.barButtonItem = barButtonItem
        }
        
        for buttonConfig in buttons {
            let action = UIAlertAction(title: buttonConfig.title, style: buttonConfig.style) { _ in
                buttonConfig.tapAction()
            }
            
            action.setValue(buttonConfig.checked, forKey: "checked")
            
            alertController.addAction(action)
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
}
