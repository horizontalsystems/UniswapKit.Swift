import UIKit
import SnapKit
import EvmKit
import RxSwift
import UniswapKit
import BigInt
import Eip20Kit

class SwapController: UIViewController {
    private var gasPrice = GasPrice.legacy(gasPrice: 50_000_000_000)
    private var disposeBag = DisposeBag()
    private var swapDataTask: Task<Void, Never>?

    private var tradeOptions = TradeOptions(allowedSlippage: 0.5)
    private let fromToken = Configuration.shared.erc20Tokens[0]
    private let toToken = Configuration.shared.erc20Tokens[1]
    private var tradeType: TradeType = .exactIn {
        didSet {
            syncCoinLabels()
        }
    }
    private var state: State = .idle
    private var fee = KitV3.FeeAmount.lowest

    private let uniswapKit = try! UniswapKit.KitV3.instance(evmKit: Manager.shared.evmKit)
    private let eip20Kit = try! Eip20Kit.Kit.instance(evmKit: Manager.shared.evmKit, contractAddress: Configuration.shared.erc20Tokens[0].contractAddress)

    private let fromLabel = UILabel()
    private let fromTextField = UITextField()
    private let toLabel = UILabel()
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

        view.addSubview(fromLabel)
        fromLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        fromLabel.font = .systemFont(ofSize: 14)
        fromLabel.textColor = .gray

        let fromTextFieldWrapper = UIView()

        view.addSubview(fromTextFieldWrapper)
        fromTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(fromLabel.snp.bottom).offset(8)
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

        view.addSubview(toLabel)
        toLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(fromTextField.snp.bottom).offset(16)
        }

        toLabel.font = .systemFont(ofSize: 14)
        toLabel.textColor = .gray

        let toTextFieldWrapper = UIView()

        view.addSubview(toTextFieldWrapper)
        toTextFieldWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(toLabel.snp.bottom).offset(8)
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

    private func syncCoinLabels() {
        let estimatedLabel = tradeType == .exactIn ? toLabel : fromLabel

        fromLabel.text = "From: \(fromToken.code)"
        toLabel.text = "To: \(toToken.code)"

        estimatedLabel.text = estimatedLabel.text.map { $0 + " (estimated)" }
    }

    private func sync(allowance: String?) {
        allowanceLabel.text = "Allowance: \((allowance ?? "N/A"))"
    }

    @objc private func syncSwapData() {
        print("Sync SwapData!")

        swapDataTask?.cancel()
        swapDataTask = nil
        swapDataTask = Task { [weak self] in
            do {
                let exactAmount: BigUInt
                let bestTrade: Quoter.BestTrade
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
                            tokenIn: .erc20(address: fromToken.contractAddress, decimals: fromToken.decimals),
                            tokenOut: .erc20(address: toToken.contractAddress, decimals: toToken.decimals),
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
                            tokenIn: .erc20(address: fromToken.contractAddress, decimals: fromToken.decimals),
                            tokenOut: .erc20(address: toToken.contractAddress, decimals: toToken.decimals),
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
        eip20Kit.allowanceSingle(spenderAddress: uniswapKit.routerAddress)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.sync(allowance: allowance)
                }, onError: { [weak self] error in
                    self?.sync(allowance: nil)
                    self?.show(error: error.localizedDescription)
                })
                .disposed(by: disposeBag)
    }

    @objc private func approve() {
        guard let amountString = fromTextField.text, let amount = Decimal(string: amountString),
              let amountIn = BigUInt(amount.hs.roundedString(decimal: fromToken.decimals)) else {
            show(error: "Invalid amount from")
            return
        }

        let transactionData = eip20Kit.approveTransactionData(spenderAddress: uniswapKit.routerAddress, amount: amountIn)

        let gasPrice = gasPrice

        disposeBag = DisposeBag()
        Manager.shared.evmKit
                .estimateGas(transactionData: transactionData, gasPrice: gasPrice)
                .subscribeOn(MainScheduler.instance)
                .flatMap { gasLimit in
                    print("GasLimit = \(gasLimit)")
                    return Manager.shared.evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                }
                .flatMap { raw in
                    do {
                        let signature = try Manager.shared.signer.signature(rawTransaction: raw)
                        return Manager.shared.evmKit.sendSingle(rawTransaction: raw, signature: signature)
                    } catch {
                        return .error(error)
                    }
                }
                .subscribe(onSuccess: { [weak self] fullTransaction in
                    self?.showSuccess(message: "Approve \(amountString) \(self?.fromToken.code ?? "Tokens")")
                }, onError: { [weak self] error in
                    self?.show(error: error.localizedDescription)
                })
                .disposed(by: disposeBag)
    }


    private func syncEstimated(tradeType: TradeType, exact: BigUInt, bestTrade: Quoter.BestTrade) {
        let decimal = tradeType == .exactIn ? toToken.decimals : fromToken.decimals
        guard let significand = Decimal(string: bestTrade.amount.description) else {
            print("Can't parse value: \(bestTrade.amount.description)")
            return
        }

        let amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)
        switch tradeType {
        case .exactIn: toTextField.text = amount.description
        case .exactOut: fromTextField.text = amount.description
        }

        let amountIn = tradeType == .exactIn ? exact : bestTrade.amount
        let amountOut = tradeType == .exactOut ? exact : bestTrade.amount
        state = .success(amountIn: amountIn, amountOut: amountOut, bestTrade: bestTrade)
    }

    @objc private func swap() {
        guard case let .success(amountIn, amountOut, bestTrade) = state else {
            show(error: "Wrong swap data")
            return
        }

        do {
            let transactionData = try uniswapKit.transactionData(
                    bestTrade: bestTrade,
                    amountIn: amountIn,
                    amountOut: amountOut,
                    tradeOptions: tradeOptions)

            let gasPrice = gasPrice

            disposeBag = DisposeBag()
            Manager.shared.evmKit
                    .estimateGas(transactionData: transactionData, gasPrice: gasPrice)
                    .subscribeOn(MainScheduler.instance)
                    .flatMap { gasLimit in
                        print("GasLimit = \(gasLimit)")
                        return Manager.shared.evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                    }
                    .flatMap { raw in
                        do {
                            let signature = try Manager.shared.signer.signature(rawTransaction: raw)
                            return Manager.shared.evmKit.sendSingle(rawTransaction: raw, signature: signature)
                        } catch {
                            return .error(error)
                        }
                    }
                    .subscribe(onSuccess: { [weak self] fullTransaction in
                        self?.showSuccess(amountIn: amountIn, amountOut: amountOut)
                    }, onError: { [weak self] error in
                        self?.show(error: error.localizedDescription)
                    })
                    .disposed(by: disposeBag)
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

}

extension SwapController {

    @objc func textFieldDidChange(_ textField: UITextField) {
        let newTradeType: TradeType = textField == fromTextField ? .exactIn : .exactOut

        print("textField did change")
        if tradeType != newTradeType {
            print("Change Trade Type to : \(newTradeType)")
            tradeType = newTradeType
        }

        if textField.text?.isEmpty ?? false {
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

    enum State {
        case idle
        case success(amountIn: BigUInt, amountOut: BigUInt, bestTrade: Quoter.BestTrade)
    }

}