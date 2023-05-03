import UIKit
import SnapKit
import EvmKit
import UniswapKit
import BigInt
import Eip20Kit

class SwapController: UIViewController {
    private var gasPrice = GasPrice.legacy(gasPrice: 1_000_000_000)
    private var estimatedCancellationTask: Task<Void, Never>?
    private var swapDataTask: Task<Void, Never>?

    private var tradeOptions = TradeOptions(allowedSlippage: 0.5)
    private var fromToken = Configuration.shared.erc20Tokens[0]
    private var toToken = Configuration.shared.erc20Tokens[1]
    private var tradeType: TradeType = .exactIn {
        didSet {
            syncCoinLabels()
        }
    }
    private var state: State = .idle
    private var fee = KitV3.FeeAmount.lowest

    private let uniswapKit = try! UniswapKit.KitV3.instance(evmKit: Manager.shared.evmKit)

    private let fromButton = UIButton()
    private let fromTextField = UITextField()
    private let toButton = UIButton()
    private let toTextField = UITextField()
    private let allowanceLabel = UILabel()
    private let maximumSoldLabel = UILabel()
    private let executionPriceLabel = UILabel()
    private let midPriceLabel = UILabel()
    private let providerFeeLabel = UILabel()
    private let pathLabel = UILabel()

    private let syncSwapDataButton = UIButton()
    private let swapButton = UIButton()
    private let syncAllowanceButton = UIButton()
    private let approveButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Swap"

        view.addSubview(fromButton)
        fromButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        fromButton.setTitleColor(.systemBlue, for: .normal)
        fromButton.titleLabel?.font = .systemFont(ofSize: 14)
        fromButton.addTarget(self, action: #selector(onTapButton(_:)), for: .touchUpInside)

        let fromTextFieldWrapper = UIView()

        view.addSubview(fromTextFieldWrapper)
        fromTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(fromButton.snp.bottom).offset(8)
        }

        fromTextFieldWrapper.borderWidth = 1
        fromTextFieldWrapper.borderColor = .black.withAlphaComponent(0.1)
        fromTextFieldWrapper.layer.cornerRadius = 8

        fromTextFieldWrapper.addSubview(fromTextField)
        fromTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        fromTextField.font = .systemFont(ofSize: 13)
        fromTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        view.addSubview(toButton)
        toButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(fromTextField.snp.bottom).offset(16)
        }

        toButton.setTitleColor(.systemBlue, for: .normal)
        toButton.titleLabel?.font = .systemFont(ofSize: 14)
        toButton.addTarget(self, action: #selector(onTapButton(_:)), for: .touchUpInside)

        let toTextFieldWrapper = UIView()

        view.addSubview(toTextFieldWrapper)
        toTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(toButton.snp.bottom).offset(8)
        }

        toTextFieldWrapper.borderWidth = 1
        toTextFieldWrapper.borderColor = .black.withAlphaComponent(0.1)
        toTextFieldWrapper.layer.cornerRadius = 8

        toTextFieldWrapper.addSubview(toTextField)
        toTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        toTextField.font = .systemFont(ofSize: 13)
        toTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        var lastView = toTextFieldWrapper
        let labels = [allowanceLabel, maximumSoldLabel, executionPriceLabel, midPriceLabel, providerFeeLabel, pathLabel]
        labels.enumerated().forEach { index, label in
            lastView.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalTo(lastView.snp.bottom).offset(index == 0 ? 24 : 16)
            }

            label.font = .systemFont(ofSize: 12)
            label.textColor = .gray
            lastView = label
        }

        pathLabel.numberOfLines = 4

        view.addSubview(syncSwapDataButton)
        syncSwapDataButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(pathLabel.snp.bottom).offset(48)
            make.height.equalTo(50)
            make.width.equalTo(200)
        }

        syncSwapDataButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        syncSwapDataButton.setTitleColor(.systemBlue, for: .normal)
        syncSwapDataButton.setTitleColor(.lightGray, for: .disabled)
        syncSwapDataButton.setTitle("Sync SwapData", for: .normal)
        syncSwapDataButton.addTarget(self, action: #selector(syncSwapData), for: .touchUpInside)

        view.addSubview(swapButton)
        swapButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(pathLabel.snp.bottom).offset(48)
            make.height.equalTo(50)
            make.width.equalTo(200)
        }

        swapButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        swapButton.setTitleColor(.systemBlue, for: .normal)
        swapButton.setTitleColor(.lightGray, for: .disabled)
        swapButton.setTitle("Swap", for: .normal)
        swapButton.addTarget(self, action: #selector(swap), for: .touchUpInside)

        view.addSubview(syncAllowanceButton)
        syncAllowanceButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(syncSwapDataButton.snp.bottom).offset(48)
            make.height.equalTo(50)
            make.width.equalTo(200)
        }

        syncAllowanceButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        syncAllowanceButton.setTitleColor(.systemBlue, for: .normal)
        syncAllowanceButton.setTitleColor(.lightGray, for: .disabled)
        syncAllowanceButton.setTitle("Sync Allowance", for: .normal)
        syncAllowanceButton.addTarget(self, action: #selector(syncAllowance), for: .touchUpInside)

        view.addSubview(approveButton)
        approveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(swapButton.snp.bottom).offset(48)
            make.height.equalTo(50)
            make.width.equalTo(200)
        }

        approveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        approveButton.setTitleColor(.systemBlue, for: .normal)
        approveButton.setTitleColor(.lightGray, for: .disabled)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.addTarget(self, action: #selector(approve), for: .touchUpInside)

        syncCoinLabels()
        sync(allowance: nil)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        view.endEditing(true)
    }

    @objc private func onTapButton(_ button: UIButton) {
        let isFrom = button == fromButton

        let viewController = TokenSelectController()
        viewController.onSelect = { [weak self] token in
            self?.syncToken(isFrom: isFrom, token: token)
        }
        present(UINavigationController(rootViewController: viewController), animated: true)
    }

    private func syncToken(isFrom: Bool, token: Erc20Token) {
        if isFrom {
            guard fromToken.code != token.code else {
                return
            }
            let oldToken = fromToken

            fromToken = token
            if toToken.code == token.code {
               toToken = oldToken
            }
        } else {
            guard toToken.code != token.code else {
                return
            }
            let oldToken = toToken

            toToken = token
            if fromToken.code == token.code {
                fromToken = oldToken
            }
        }
        syncCoinLabels()

        let textField = tradeType == .exactIn ? fromTextField : toTextField
        guard checkValidAmount(text: textField.text) else {
            return
        }

        syncSwapData()
    }

    private func syncCoinLabels() {
        let fromText = "From: \(fromToken.code)" + (tradeType == .exactIn ? "" : " (estimated)")
        let toText = "To: \(toToken.code)" + (tradeType == .exactOut ? "" : " (estimated)")

        fromButton.setTitle(fromText, for: .normal)
        toButton.setTitle(toText, for: .normal)
    }

    private func sync(allowance: String?) {
        allowanceLabel.text = "Allowance: \((allowance ?? "N/A"))"
    }

    @objc private func syncSwapData() {
        print("Sync SwapData!")

        swapDataTask?.cancel()
        swapDataTask = Task { [weak self] in
            do {
                let exactAmount: BigUInt
                let bestTrade: TradeDataV3
                switch tradeType {
                case .exactIn:
                    guard let amountString = fromTextField.text, let amount = Decimal(string: amountString),
                          let amountBigUInt = BigUInt(amount.hs.roundedString(decimal: fromToken.decimals))
                    else {
                        self?.show(error: "Invalid amount from")
                        return
                    }

                    exactAmount = amountBigUInt
                    bestTrade = try await uniswapKit.bestTradeExactIn(
                            tokenIn: token(fromToken),
                            tokenOut: token(toToken),
                            amountIn: amount
                    )
                case .exactOut:
                    guard let amountString = toTextField.text, let amount = Decimal(string: amountString),
                          let amountBigUInt = BigUInt(amount.hs.roundedString(decimal: toToken.decimals))
                    else {

                        show(error: "Invalid amount to")
                        return
                    }

                    exactAmount = amountBigUInt
                    bestTrade = try await uniswapKit.bestTradeExactOut(
                            tokenIn: token(fromToken),
                            tokenOut: token(toToken),
                            amountOut: amount
                    )
                }

                let tradeType = tradeType
                self?.syncEstimated(tradeType: tradeType, exact: exactAmount, bestTrade: bestTrade)
            } catch {
                self?.state = .idle
                self?.show(error: error.localizedDescription)
            }
        }
    }

    @objc private func syncAllowance() {
        let token = token(fromToken)
        if token.isEther {
            sync(allowance: nil)
            return
        }
        Task {
            do {
                let eip20Kit = try Eip20Kit.Kit.instance(evmKit: Manager.shared.evmKit, contractAddress: token.address)
                let allowance = try await eip20Kit.allowance(spenderAddress: uniswapKit.routerAddress)
                sync(allowance: allowance)
            } catch {
                sync(allowance: nil)
                show(error: error.localizedDescription)
            }
        }
    }

    @objc private func approve() {
        guard let amountString = fromTextField.text, let amount = Decimal(string: amountString),
              let amountIn = BigUInt(amount.hs.roundedString(decimal: fromToken.decimals)) else {
            show(error: "Invalid amount from")
            return
        }

        guard let eip20Kit = try? Eip20Kit.Kit.instance(evmKit: Manager.shared.evmKit, contractAddress: token(fromToken).address) else {
            show(error: "Can't create Eip20 Kit for token!")
            return
        }
        let transactionData = eip20Kit.approveTransactionData(spenderAddress: uniswapKit.routerAddress, amount: amountIn)

        let gasPrice = gasPrice

        estimatedCancellationTask?.cancel()
        estimatedCancellationTask = Task { [weak self] in
            do {
                let gasLimit = try await Manager.shared.evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
                print("GasLimit = \(gasLimit)")
                let raw = try await Manager.shared.evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)

                let signature = try Manager.shared.signer.signature(rawTransaction: raw)
                let _ = try await Manager.shared.evmKit.send(rawTransaction: raw, signature: signature)

                self?.showSuccess(message: "Approve \(amountString) \(self?.fromToken.code ?? "Tokens")")
            } catch {
                self?.show(error: error.localizedDescription)
            }
        }
    }


    private func syncEstimated(tradeType: TradeType, exact: BigUInt, bestTrade: TradeDataV3) {
        let estimatedAmount = tradeType == .exactIn ? bestTrade.tradeAmountOut : bestTrade.tradeAmountIn

        switch tradeType {
        case .exactIn: toTextField.text = estimatedAmount?.description
        case .exactOut: fromTextField.text = estimatedAmount?.description
        }

        state = .success(bestTrade: bestTrade)
    }

    @objc private func swap() {
        guard case let .success(bestTrade) = state else {
            show(error: "Wrong swap data")
            return
        }

        do {
            let transactionData = try uniswapKit.transactionData(
                    bestTrade: bestTrade,
                    tradeOptions: tradeOptions)

            print("tx input: " , transactionData.input.hs.hexString)
            let gasPrice = gasPrice
            Task { [weak self] in
                do {
                    let gasLimit = try await Manager.shared.evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
                    print("GasLimit = \(gasLimit)")
                    let raw = try await Manager.shared.evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)

                    let signature = try Manager.shared.signer.signature(rawTransaction: raw)
                    let _ = try await Manager.shared.evmKit.send(rawTransaction: raw, signature: signature)

                    self?.showSuccess(message: "Send successful! \(bestTrade.tradeAmountIn?.description) \(bestTrade.tradeAmountOut?.description)")
                } catch {
                    self?.show(error: error.localizedDescription)
                }
            }
        } catch {
            show(error: error.localizedDescription)
        }
    }

    private func onSend(tx: FullTransaction) {
        print("Successfully send!")
    }

    private func show(error: String) {
        let alert = UIAlertController(title: "Swap Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showSuccess(amountIn: BigUInt, amountOut: BigUInt) {
        DispatchQueue.main.async {
            self.showSuccess(message: "\(amountIn.description) swap to \(amountOut.description)")
        }
    }

    private func showSuccess(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func checkValidAmount(text: String?) -> Bool {
        let text = text ?? ""
        if text.isEmpty {
            return false
        }
        if let decimalValue = Decimal(string: text), !decimalValue.isZero {
            return true
        }
        return false
    }

}

extension SwapController {

    @objc func textFieldDidChange(_ textField: UITextField) {
        let newTradeType: TradeType = textField == fromTextField ? .exactIn : .exactOut

        print("textField did change")
        if tradeType != newTradeType {
            print("Change Trade Type to : \(newTradeType)")
            tradeType = newTradeType
        }

        if !checkValidAmount(text: textField.text) {
            switch newTradeType {
            case .exactIn: toTextField.text = ""
            case .exactOut: fromTextField.text = ""
            }
            return
        }

        syncSwapData()
    }

}

extension SwapController {

    func token(_ erc20Token: Erc20Token) -> Token {
        guard let contractAddress = erc20Token.contractAddress else {
            return uniswapKit.etherToken
        }

        return .erc20(address: contractAddress, decimals: erc20Token.decimals)
    }

    enum State {
        case idle
        case success(bestTrade: TradeDataV3)
    }

}
