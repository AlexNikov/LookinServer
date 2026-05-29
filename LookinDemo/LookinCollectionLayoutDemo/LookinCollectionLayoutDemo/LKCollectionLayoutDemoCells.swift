import UIKit

enum LKDemoCollectionSection: Int {
    case autoLayout = 0
    case frameLayout = 1
    case mixed = 2
}

func LKDemoCollectionSectionTitle(_ section: LKDemoCollectionSection) -> String {
    switch section {
    case .autoLayout: return "Auto Layout cells"
    case .frameLayout: return "Frame layout cells"
    case .mixed: return "Mixed (AL + frame)"
    }
}

func LKDemoCollectionSectionItemCount(_ section: LKDemoCollectionSection) -> Int {
    switch section {
    case .autoLayout: return 10
    case .frameLayout: return 10
    case .mixed: return 8
    }
}

private func LKDemoApplyAccessibility(
    to view: UIView,
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

// MARK: - Frame badge strip (mixed cells)

private final class LKDemoFrameBadgeStripView: UIView {
    private var chips: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        LKDemoApplyAccessibility(
            to: self,
            identifier: "mixedInnerFrameStrip",
            label: "Frame badge strip",
            value: "5 chips",
            hint: "Inner frame-layout chips inside mixed cell",
            traits: .staticText
        )
        for i in 0..<5 {
            let chip = UIView()
            chip.backgroundColor = UIColor(hue: CGFloat(i) * 0.18, saturation: 0.55, brightness: 0.95, alpha: 1)
            chip.layer.cornerRadius = 4
            addSubview(chip)
            chips.append(chip)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let chipW: CGFloat = 28
        let gap: CGFloat = 6
        var x: CGFloat = 0
        let y = (bounds.height - 18) / 2.0
        for chip in chips {
            chip.frame = CGRect(x: x, y: y, width: chipW, height: 18)
            x += chipW + gap
        }
    }
}

// MARK: - Left rail

final class LKDemoLeftRailView: UIView {
    private let titleLabel = UILabel()
    private let modeLabel = UILabel()
    private var blocks: [UIView] = []
    private var labels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        LKDemoApplyAccessibility(
            to: self,
            identifier: "leftRailFrameLayout",
            label: "Left rail",
            value: "Frame layout sidebar",
            hint: "Fixed-width rail with colored blocks",
            isElement: false
        )
        backgroundColor = .secondarySystemGroupedBackground
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor

        titleLabel.text = "Left rail"
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        modeLabel.text = "frame"
        modeLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        modeLabel.textColor = .systemOrange
        modeLabel.textAlignment = .center
        addSubview(modeLabel)

        let colors: [UIColor] = [
            .systemRed, .systemGreen, .systemBlue,
            .systemPurple, .systemTeal, .systemPink,
        ]
        for idx in 0..<colors.count {
            let block = UIView()
            block.backgroundColor = colors[idx]
            block.layer.cornerRadius = 6
            LKDemoApplyAccessibility(
                to: block,
                identifier: "rail_block_\(idx)",
                label: "Rail block \(idx)",
                value: "Color swatch f\(idx)",
                hint: "Frame-positioned block in left rail",
                traits: .image
            )
            addSubview(block)
            blocks.append(block)

            let caption = UILabel()
            caption.text = "f\(idx)"
            caption.font = .systemFont(ofSize: 10, weight: .medium)
            caption.textAlignment = .center
            addSubview(caption)
            labels.append(caption)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        titleLabel.frame = CGRect(x: 8, y: 12, width: w - 16, height: 20)
        modeLabel.frame = CGRect(x: 8, y: 34, width: w - 16, height: 14)
        var y: CGFloat = 58
        for idx in 0..<blocks.count {
            let size: CGFloat = idx % 2 == 0 ? 44 : 36
            let x: CGFloat = 12 + CGFloat(idx % 2) * 8
            let block = blocks[idx]
            block.frame = CGRect(x: x, y: y, width: size, height: size)
            labels[idx].frame = CGRect(
                x: block.frame.maxX + 4,
                y: y + 10,
                width: w - block.frame.maxX - 12,
                height: 16
            )
            y = block.frame.maxY + 10
        }
    }
}

// MARK: - Auto Layout cell

final class LKDemoConstraintCollectionCell: UICollectionViewCell {
    static let reuseID = "LKDemoConstraintCollectionCell"

    private let badge = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let swatch = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 10

        badge.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = .systemBlue
        badge.textAlignment = .center
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        swatch.layer.cornerRadius = 8
        swatch.translatesAutoresizingMaskIntoConstraints = false

        for v in [badge, titleLabel, subtitleLabel, swatch] {
            contentView.addSubview(v)
        }
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            badge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            badge.widthAnchor.constraint(equalToConstant: 52),
            badge.heightAnchor.constraint(equalToConstant: 18),
            swatch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            swatch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            swatch.widthAnchor.constraint(equalToConstant: 48),
            swatch.heightAnchor.constraint(equalToConstant: 48),
            titleLabel.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: swatch.leadingAnchor, constant: -8),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(index: Int) {
        let title = "Constraint row \(index + 1)"
        titleLabel.text = title
        subtitleLabel.text = "NSLayoutConstraint inside cell"
        badge.text = "AL"
        swatch.backgroundColor = UIColor(hue: CGFloat(index) * 0.07, saturation: 0.45, brightness: 0.9, alpha: 1)
        LKDemoApplyAccessibility(
            to: self,
            identifier: "cell_constraint_\(index)",
            label: title,
            value: "Auto Layout cell",
            hint: "Collection cell laid out with NSLayoutConstraint",
            traits: .staticText
        )
    }
}

// MARK: - Frame layout cell

final class LKDemoFrameCollectionCell: UICollectionViewCell {
    static let reuseID = "LKDemoFrameCollectionCell"

    private let badge = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let swatch = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 10

        badge.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = .systemOrange
        badge.textAlignment = .center
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        swatch.layer.cornerRadius = 8

        for v in [badge, titleLabel, subtitleLabel, swatch] {
            contentView.addSubview(v)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let b = contentView.bounds
        badge.frame = CGRect(x: 12, y: 10, width: 52, height: 18)
        swatch.frame = CGRect(x: b.width - 60, y: (b.height - 48) / 2.0, width: 48, height: 48)
        titleLabel.frame = CGRect(x: 12, y: badge.frame.maxY + 8, width: swatch.frame.minX - 20, height: 20)
        subtitleLabel.frame = CGRect(x: 12, y: titleLabel.frame.maxY + 4, width: titleLabel.frame.width, height: 16)
    }

    func configure(index: Int) {
        let title = "Frame row \(index + 1)"
        badge.text = "frame"
        titleLabel.text = title
        subtitleLabel.text = "layoutSubviews + CGRect"
        swatch.backgroundColor = UIColor(hue: 0.55 + CGFloat(index) * 0.05, saturation: 0.5, brightness: 0.88, alpha: 1)
        LKDemoApplyAccessibility(
            to: self,
            identifier: "cell_frame_\(index)",
            label: title,
            value: "Frame layout cell",
            hint: "Collection cell positioned with CGRect frames",
            traits: .staticText
        )
        setNeedsLayout()
    }
}

// MARK: - Mixed cell

final class LKDemoMixedCollectionCell: UICollectionViewCell {
    static let reuseID = "LKDemoMixedCollectionCell"

    private let titleLabel = UILabel()
    private let badgeStrip = LKDemoFrameBadgeStripView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 10

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeStrip.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeStrip)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            badgeStrip.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            badgeStrip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            badgeStrip.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),
            badgeStrip.heightAnchor.constraint(equalToConstant: 22),
            badgeStrip.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(index: Int) {
        let title = "Mixed \(index + 1) — AL title + frame chips"
        titleLabel.text = title
        LKDemoApplyAccessibility(
            to: self,
            identifier: "cell_mixed_\(index)",
            label: title,
            value: "Mixed layout cell",
            hint: "Auto Layout title with frame-layout badge strip",
            traits: .staticText
        )
    }
}

// MARK: - Section header

final class LKDemoSectionHeaderView: UICollectionReusableView {
    static let reuseID = "LKDemoSectionHeaderView"

    private let titleLabel = UILabel()
    private var dots: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        for _ in 0..<4 {
            let dot = UIView()
            dot.backgroundColor = .tertiaryLabel
            dot.layer.cornerRadius = 3
            addSubview(dot)
            dots.append(dot)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        var x = bounds.width - 56
        let y = (bounds.height - 6) / 2.0
        for dot in dots {
            dot.frame = CGRect(x: x, y: y, width: 6, height: 6)
            x += 12
        }
    }

    func configure(title: String, section: Int) {
        titleLabel.text = title
        LKDemoApplyAccessibility(
            to: self,
            identifier: "section_header_\(section)",
            label: title,
            value: "Section \(section)",
            hint: "Collection section header",
            traits: .header
        )
    }
}
