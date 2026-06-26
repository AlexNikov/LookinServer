import UIKit

final class LKCollectionLayoutDemoViewController: UIViewController, UICollectionViewDelegate {
    private let leftRail = LKDemoLeftRailView()
    private var collectionView: UICollectionView!
    private let stackView = UIStackView()
    private let topButton = UIButton(type: .system)
    private let bottomButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        applyAccessibility(
            to: view,
            identifier: "collectionLayoutRoot",
            label: "Collection Layout Demo",
            hint: "Demo for Auto Layout vs frame layout inspection",
            isElement: false
        )

        leftRail.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftRail)
        NSLayoutConstraint.activate([
            leftRail.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftRail.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            leftRail.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leftRail.widthAnchor.constraint(equalToConstant: 132),
        ])

        topButton.setTitle("Show Alert", for: .normal)
        topButton.addTarget(self, action: #selector(topButtonTapped), for: .touchUpInside)
        applyAccessibility(
            to: topButton,
            identifier: "topAlertButton",
            label: "Show Alert",
            hint: "Presents an alert controller",
            traits: .button
        )

        bottomButton.setTitle("Show Action Sheet", for: .normal)
        bottomButton.addTarget(self, action: #selector(bottomButtonTapped), for: .touchUpInside)
        applyAccessibility(
            to: bottomButton,
            identifier: "bottomActionSheetButton",
            label: "Show Action Sheet",
            hint: "Presents an action sheet",
            traits: .button
        )

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        applyAccessibility(
            to: stackView,
            identifier: "mainContentStack",
            label: "Main content stack",
            hint: "Vertical stack with alert button, collection, and action sheet button",
            isElement: false
        )

        let layout = makeLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.setContentHuggingPriority(.defaultLow, for: .vertical)
        collectionView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        applyAccessibility(
            to: collectionView,
            identifier: "mainCollectionView",
            label: "Main collection",
            value: "3 sections, 28 cells",
            hint: "Scrollable collection of layout demo cells",
            isElement: false
        )
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.delegate = self
        collectionView.dataSource = self

        stackView.addArrangedSubview(topButton)
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(bottomButton)
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leftRail.trailingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topButton.heightAnchor.constraint(equalToConstant: 44),
            bottomButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        collectionView.register(
            LKDemoConstraintCollectionCell.self,
            forCellWithReuseIdentifier: LKDemoConstraintCollectionCell.reuseID
        )
        collectionView.register(
            LKDemoFrameCollectionCell.self,
            forCellWithReuseIdentifier: LKDemoFrameCollectionCell.reuseID
        )
        collectionView.register(
            LKDemoMixedCollectionCell.self,
            forCellWithReuseIdentifier: LKDemoMixedCollectionCell.reuseID
        )
        collectionView.register(
            LKDemoSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: LKDemoSectionHeaderView.reuseID
        )
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            let section = LKDemoCollectionSection(rawValue: sectionIndex) ?? .autoLayout
            var itemH: CGFloat = 92
            if section == .frameLayout { itemH = 88 }
            if section == .mixed { itemH = 72 }

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemH)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemH + 8)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(36)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            let layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.boundarySupplementaryItems = [header]
            layoutSection.interGroupSpacing = 4

            if section == .frameLayout, environment.container.effectiveContentSize.width > 500 {
                let pairGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: 2
                )
                pairGroup.interItemSpacing = .fixed(8)
                let wide = NSCollectionLayoutSection(group: pairGroup)
                wide.boundarySupplementaryItems = [header]
                return wide
            }
            return layoutSection
        }
    }

    @objc private func topButtonTapped() {
        let alert = UIAlertController(
            title: "Alert",
            message: "Shown from the top button.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func bottomButtonTapped() {
        let sheet = UIAlertController(
            title: "Action Sheet",
            message: "Shown from the bottom button.",
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: "Option A", style: .default))
        sheet.addAction(UIAlertAction(title: "Option B", style: .default))
        sheet.addAction(UIAlertAction(title: "Close", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = bottomButton
            popover.sourceRect = bottomButton.bounds
        }
        present(sheet, animated: true)
    }
}

extension LKCollectionLayoutDemoViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let demoSection = LKDemoCollectionSection(rawValue: section) else { return 0 }
        return LKDemoCollectionSectionItemCount(demoSection)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let section = LKDemoCollectionSection(rawValue: indexPath.section) else {
            fatalError("Unexpected section")
        }
        switch section {
        case .autoLayout:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: LKDemoConstraintCollectionCell.reuseID,
                for: indexPath
            ) as! LKDemoConstraintCollectionCell
            cell.configure(index: indexPath.item)
            return cell
        case .frameLayout:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: LKDemoFrameCollectionCell.reuseID,
                for: indexPath
            ) as! LKDemoFrameCollectionCell
            cell.configure(index: indexPath.item)
            return cell
        case .mixed:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: LKDemoMixedCollectionCell.reuseID,
                for: indexPath
            ) as! LKDemoMixedCollectionCell
            cell.configure(index: indexPath.item)
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: LKDemoSectionHeaderView.reuseID,
            for: indexPath
        ) as! LKDemoSectionHeaderView
        let section = LKDemoCollectionSection(rawValue: indexPath.section) ?? .autoLayout
        header.configure(title: LKDemoCollectionSectionTitle(section), section: indexPath.section)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let section = LKDemoCollectionSection(rawValue: indexPath.section) else { return }
        let alert = UIAlertController(
            title: "Cell Alert",
            message: "\(LKDemoCollectionSectionTitle(section)) — item \(indexPath.item + 1)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func applyAccessibility(
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
}
