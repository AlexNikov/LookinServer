import UIKit

final class SampleViewController: UIViewController {
    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let colorBlock = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
    }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Lookin MCP Sample"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Tap me", for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        actionButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        colorBlock.translatesAutoresizingMaskIntoConstraints = false
        colorBlock.backgroundColor = UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1.0)
        colorBlock.layer.cornerRadius = 12

        view.addSubview(titleLabel)
        view.addSubview(actionButton)
        view.addSubview(colorBlock)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            actionButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            colorBlock.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 40),
            colorBlock.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorBlock.widthAnchor.constraint(equalToConstant: 120),
            colorBlock.heightAnchor.constraint(equalToConstant: 120),
        ])

        configureAccessibility(
            on: view,
            identifier: "mcp.root",
            label: "MCP Sample",
            hint: "Lookin MCP UI verify demo screen",
            isElement: false
        )
        configureAccessibility(
            on: titleLabel,
            identifier: "mcp.titleLabel",
            label: "Screen title",
            value: titleLabel.text,
            hint: "Static heading label",
            traits: .staticText
        )
        configureAccessibility(
            on: actionButton,
            identifier: "mcp.actionButton",
            label: "Tap me",
            value: "Normal",
            hint: "Toggles color block between blue and orange",
            traits: .button
        )
        configureAccessibility(
            on: colorBlock,
            identifier: "mcp.colorBlock",
            label: "Color preview",
            value: "Blue",
            hint: "Decorative color swatch",
            traits: .image
        )
    }

    private func configureAccessibility(
        on view: UIView,
        identifier: String,
        label: String,
        value: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits = [],
        isElement: Bool = true,
        elementsHidden: Bool = false,
        viewIsModal: Bool = false
    ) {
        view.accessibilityIdentifier = identifier
        view.accessibilityLabel = label
        view.accessibilityValue = value
        view.accessibilityHint = hint
        view.isAccessibilityElement = isElement
        view.accessibilityTraits = traits
        view.accessibilityElementsHidden = elementsHidden
        view.accessibilityViewIsModal = viewIsModal
    }

    @objc private func handleTap() {
        colorBlock.backgroundColor = colorBlock.backgroundColor == .systemOrange
            ? UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1.0)
            : .systemOrange
    }
}
