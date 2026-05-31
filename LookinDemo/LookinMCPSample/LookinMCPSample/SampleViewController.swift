import UIKit

final class SampleViewController: UIViewController {

    // MARK: - Top section (existing)
    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let colorBlock = UIView()

    // MARK: - Scroll section (new)
    private let scrollView = UIScrollView()
    private let scrollLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTopSection()
        setupScrollSection()
    }

    // MARK: - Top section

    private func setupTopSection() {
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
    }

    @objc private func handleTap() {
        colorBlock.backgroundColor = colorBlock.backgroundColor == .systemOrange
            ? UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1.0)
            : .systemOrange
    }

    // MARK: - Scroll section

    private func setupScrollSection() {
        // Container label above the scroll view
        let sectionLabel = UILabel()
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        sectionLabel.text = "ScrollView (swipe to scroll):"
        sectionLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        sectionLabel.textColor = .secondaryLabel
        view.addSubview(sectionLabel)

        // ScrollView fixed to bottom half of the screen
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.systemGroupedBackground
        scrollView.layer.cornerRadius = 12
        scrollView.showsVerticalScrollIndicator = true
        scrollView.accessibilityIdentifier = "mainScrollView"
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: colorBlock.bottomAnchor, constant: 28),
            sectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            scrollView.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
        ])

        // Content stack inside scroll view
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        // Add 20 rows
        let colors: [UIColor] = [
            .systemRed, .systemOrange, .systemYellow, .systemGreen,
            .systemTeal, .systemBlue, .systemIndigo, .systemPurple,
            .systemPink, .systemBrown,
        ]
        for i in 0..<20 {
            let row = makeRow(index: i, color: colors[i % colors.count])
            stack.addArrangedSubview(row)
            let sep = UIView()
            sep.backgroundColor = .separator
            sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            stack.addArrangedSubview(sep)
        }
    }

    private func makeRow(index: Int, color: UIColor) -> UIView {
        let row = UIView()
        row.backgroundColor = .secondarySystemGroupedBackground
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = color
        dot.layer.cornerRadius = 8
        dot.widthAnchor.constraint(equalToConstant: 16).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Row \(index + 1)"
        label.font = .systemFont(ofSize: 16)
        label.accessibilityIdentifier = "row_\(index)"

        row.addSubview(dot)
        row.addSubview(label)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            dot.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
    }
}
