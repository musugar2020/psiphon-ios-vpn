 /*
 * Copyright (c) 2019, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import UIKit
import StoreKit
import PsiApi
import AppStoreIAP
import PsiCashClient

struct PsiCashPurchasableViewModel: Equatable {
    enum ProductType: Equatable {
        case product(AppStoreProduct)
    }
    let product: ProductType
    let title: String
    let subtitle: String
    let localizedPrice: LocalizedPrice
    let clearedForSale: Bool
}

struct PsiCashCoinPurchaseTable: ViewBuilder {
    
    struct ViewModel: Equatable {
        let purchasables: [PsiCashPurchasableViewModel]
        let footerText: String?
    }
    
    let purchaseHandler: (PsiCashPurchasableViewModel.ProductType) -> Void

    func build(
        _ container: UIView?
    ) -> ImmutableBindableViewable<ViewModel, PsiCashCoinTable> {
        .init(viewable: PsiCashCoinTable(purchaseHandler: purchaseHandler))
        { table -> ((ViewModel) -> Void) in
            return {
                table.bind($0)
            }
        }
    }
}

final class PsiCashCoinTable: NSObject, ViewWrapper, Bindable, UITableViewDataSource,
UITableViewDelegate {

    private let PurchaseCellID = "PurchaseCellID"
    private let FooterCellID = "FooterCellID"
    private let priceFormatter = CurrencyFormatter(locale: Locale.current)
    private var data: PsiCashCoinPurchaseTable.ViewModel
    private let table: UITableView
    private let purchaseHandler: (PsiCashPurchasableViewModel.ProductType) -> Void
    var numRows: Int {
        data.purchasables.count + (data.footerText.hasValue ? 1 : 0)
    }

    var view: UIView { table }

    init(purchaseHandler: @escaping (PsiCashPurchasableViewModel.ProductType) -> Void) {
        self.data = .init(purchasables: [], footerText: nil)
        self.purchaseHandler = purchaseHandler
        table = UITableView(frame: .zero, style: .plain)
        super.init()
        table.register(UITableViewCell.self, forCellReuseIdentifier: PurchaseCellID)
        table.register(UITableViewCell.self, forCellReuseIdentifier: FooterCellID)
        table.dataSource = self
        table.delegate = self

        // UI Properties
        table.backgroundColor = .clear
        table.allowsSelection = false
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = Style.default.largeButtonHeight
    }

    func bind(_ newValue: PsiCashCoinPurchaseTable.ViewModel) {
        guard data != newValue else { return }
        data = newValue
        table.reloadData()
    }

    // MARK: UITableViewDelegate

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0..<data.purchasables.count:
            let cell = tableView.dequeueReusableCell(withIdentifier: PurchaseCellID, for: indexPath)
            let cellData = data.purchasables[indexPath.row]
            if !cell.hasContent {
                let content = PurchaseCellContent(priceFormatter: self.priceFormatter,
                                                  clickHandler: self.purchaseHandler)
                cell.contentView.addSubview(content)
                content.activateConstraints {
                    $0.matchParentConstraints(bottom: -10)
                }

                // UI properties
                cell.backgroundColor = .clear
            }

            guard let content = cell.contentView.subviews[maybe: 0] as? PurchaseCellContent else {
                fatalError("Expected cell to have subview of type 'PurchaseCellContent'")
            }

            content.bind(cellData)
            return cell

        case numRows - 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: FooterCellID, for: indexPath)
            
            if !cell.hasContent {
                addUILabelTo(toCell: cell)
            }
            
            let footerView = cell.contentView.subviews[0] as! UILabel
            footerView.text = data.footerText!
            
            if case .rightToLeft = UIApplication.shared.userInterfaceLayoutDirection {
                footerView.textAlignment = .right
            }
            
            return cell

        default:
            fatalError("Unexpected IndexPath '\(indexPath)'")
        }
    }
}

fileprivate func addUILabelTo(toCell cell: UITableViewCell) {
    cell.backgroundColor = .clear
    cell.selectionStyle = .none

    let label = UILabel.make(
        fontSize: .normal,
        typeface: .medium,
        color: .blueGrey(),
        numberOfLines: 0)

    cell.contentView.addSubview(label)

    let padding = Float(20.0)
    label.activateConstraints {
        $0.constraintToParent(.leading(padding), .trailing(-padding),
                              .top(padding), .bottom(-2 * padding))
    }
}

fileprivate final class PurchaseCellContent: UIView, Bindable {
    private let topPad: Float = 14
    private let bottomPad: Float = -14
    private let priceFormatter: CurrencyFormatter
    private let titleLabel: UILabel
    private let subtitleLabel: UILabel
    private let button: GradientButton
    private let spinner: UIActivityIndicatorView
    private let clickHandler: (PsiCashPurchasableViewModel.ProductType) -> Void

    init(priceFormatter: CurrencyFormatter,
         clickHandler: @escaping (PsiCashPurchasableViewModel.ProductType) -> Void) {
        self.priceFormatter = priceFormatter
        self.clickHandler = clickHandler
        
        titleLabel = UILabel.make(fontSize: .h3, typeface: .bold)
        subtitleLabel = UILabel.make(fontSize: .subtitle, numberOfLines: 0)
        button = GradientButton(shadow: .light, contentShadow: false, gradient: .grey)
        spinner = .init(style: .gray)
        super.init(frame: .zero)

        // View properties
        addShadow(toLayer: layer)
        layer.cornerRadius = Style.default.cornerRadius
        backgroundColor = .white(withAlpha: 0.42)
        button.setTitleColor(.darkBlue(), for: .normal)
        
        button.titleLabel!.apply(fontSize: .h3,
                                 typeface: .bold,
                                 color: .darkBlue())
        
        button.contentEdgeInsets = Style.default.buttonMinimumContentEdgeInsets
        
        spinner.isHidden = true

        // Setup subviews
        let hStack = UIStackView.make(
            axis: .horizontal,
            distribution: .fill,
            alignment: .center,
            spacing: 10.0
        )
        
        let titleStack = UIStackView.make(
            axis: .vertical,
            distribution: .fill,
            alignment: .fill,
            spacing: 3.0
        )
        
        let imageView = UIImageView.make(image: "PsiCashCoin_Large")
        
        button.addSubview(spinner)
        
        spinner.activateConstraints {
            $0.constraint(to: button, [.centerX(0), .centerY(0)])
        }
        
        titleStack.addArrangedSubviews(
            titleLabel,
            subtitleLabel
        )
        
        hStack.addArrangedSubviews(
            imageView,
            titleStack,
            button
        )
        
        self.addSubview(hStack)

        // Setup auto layout for subviews
        
        hStack.activateConstraints {
            $0.constraintToParent(.top(10), .bottom(-10), .leading(10), .trailing(-10))
        }
                
        imageView.activateConstraints {[
            $0.widthAnchor.constraint(equalTo: hStack.widthAnchor,
                                      multiplier: 0.11).priority(.belowRequired),
            $0.heightAnchor.constraint(equalTo: $0.widthAnchor).priority(.required)
        ]}
        
        
        titleStack.activateConstraints {[
            $0.widthAnchor.constraint(lessThanOrEqualTo: hStack.widthAnchor,
                                      multiplier: 0.4).priority(.belowRequired)
        ]}
        
        button.activateConstraints {
            $0.widthAnchor.constraint(default: 80.0, max: 160.0) + [
                $0.widthAnchor.constraint(equalTo: hStack.widthAnchor,
                                          multiplier: 0.3).priority(.belowRequired),
                $0.widthAnchor.constraint(lessThanOrEqualTo: hStack.widthAnchor,
                                          multiplier: 0.35).priority(.required),
                $0.heightAnchor.constraint(equalTo: titleLabel.heightAnchor,
                                           multiplier: 1.5).priority(.belowRequired)
            ]
        }
        
        button.setContentHuggingPriority(higherThan: titleStack, for: .horizontal)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(_ newValue: PsiCashPurchasableViewModel) {
        
        // Forces title and subtitle text alignment, since they may not have translations.
        if case .rightToLeft = UIApplication.shared.userInterfaceLayoutDirection {
            titleLabel.textAlignment = .right
            subtitleLabel.textAlignment = .right
        }
        
        titleLabel.text = newValue.title
        subtitleLabel.text = newValue.subtitle

        button.setEventHandler { [unowned self] in
            self.clickHandler(newValue.product)
        }
        
        // Gives the button a "disabled" look when not cleared for sale.
        if newValue.clearedForSale {
            button.isEnabled = true
            button.setTitleColor(.darkBlue(), for: .normal)
        } else {
            button.isEnabled = false
            button.setTitleColor(.gray, for: .normal)
        }

        spinner.isHidden = true
        spinner.stopAnimating()
        switch newValue.localizedPrice {
        case .free:
            button.setTitle(UserStrings.Free(), for: .normal)
        case let .localizedPrice(price: price, priceLocale: priceLocale):
            priceFormatter.locale = priceLocale.locale
            button.setTitle(priceFormatter.string(from: price), for: .normal)
        }

    }
}
