import UIKit

final class LKCollectionLayoutDemoViewController: UIViewController, UICollectionViewDelegate {
    private let leftRail = LKDemoLeftRailView()
    private var collectionView: UICollectionView!

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

        let layout = makeLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        applyAccessibility(
            to: collectionView,
            identifier: "mainCollectionView",
            label: "Main collection",
            value: "3 sections, 28 cells",
            hint: "Scrollable collection of layout demo cells",
            isElement: false
        )
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leftRail.trailingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
