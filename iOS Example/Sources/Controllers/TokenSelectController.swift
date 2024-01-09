import UIExtensions
import UIKit

class TokenSelectController: UITableViewController {
    var onSelect: ((Erc20Token) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Token Select"

        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        Configuration.shared.erc20Tokens.count
    }

    override func tableView(_: UITableView, cellForRowAt _: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }

    override func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let token = Configuration.shared.erc20Tokens[indexPath.row]
        cell.textLabel?.text = token.name + " : " + token.code
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect?(Configuration.shared.erc20Tokens[indexPath.row])

        dismiss(animated: true)
    }
}
