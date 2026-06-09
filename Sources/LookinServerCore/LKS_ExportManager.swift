#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

@objc(LKS_ExportManager)
public final class LKS_ExportManager: NSObject {

    @objc public class func sharedInstance() -> LKS_ExportManager {
        SharedStorage.instance
    }

    #if !os(tvOS)
    private var documentController: UIDocumentInteractionController?
    #endif

    private var maskView: MaskView?

    private override init() {
        super.init()
    }

    @objc public func exportAndShare() {
        #if os(tvOS)
        assertionFailure("not supported")
        #else
        exportAndShareOnSupportedPlatform()
        #endif
    }

    #if !os(tvOS)
    private func exportAndShareOnSupportedPlatform() {
        guard let visibleVc = UIViewController.lks_visibleViewController() else {
            NSLog("LookinServer - Failed to export because we didn't find any visible view controller.")
            return
        }

        NotificationCenter.default.post(name: .lookinWillExport, object: nil)

        if maskView == nil {
            maskView = MaskView()
        }
        guard let maskView, let window = visibleVc.view.window else { return }

        window.addSubview(maskView)
        maskView.frame = window.bounds

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            let info = LookinHierarchyInfo.exportedInfo()
            var file = LookinHierarchyFile()
            file.serverVersion = info.serverVersion
            file.hierarchyInfo = info

            guard let data = try? WireLookinFileCodec.data(from: file) else { return }

            let fileName = Self.makeFileName(for: info)
            let path = NSTemporaryDirectory() + fileName
            try? data.write(to: URL(fileURLWithPath: path), options: .atomic)

            self.maskView?.removeFromSuperview()

            if self.documentController == nil {
                self.documentController = UIDocumentInteractionController()
            }
            self.documentController?.url = URL(fileURLWithPath: path)

            if LKS_MultiplatformAdapter.isiPad() {
                self.documentController?.presentOpenInMenu(
                    from: CGRect(x: 0, y: 0, width: 1, height: 1),
                    in: visibleVc.view,
                    animated: true
                )
            } else {
                self.documentController?.presentOpenInMenu(
                    from: visibleVc.view.bounds,
                    in: visibleVc.view,
                    animated: true
                )
            }

            NotificationCenter.default.post(name: .lookinDidFinishExport, object: nil)
        }
    }

    private static func makeFileName(for info: LookinHierarchyInfo) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddHHmm"
        let timeString = formatter.string(from: Date())

        var iOSVersion = info.appInfo?.osDescription ?? ""
        if let dotIdx = iOSVersion.firstIndex(of: ".") {
            iOSVersion = String(iOSVersion[..<dotIdx])
        }

        return "\(info.appInfo?.appName ?? "App")_ios\(iOSVersion)_\(timeString).lookin"
    }

    private final class MaskView: UIView {
        private let tipsView = UIView()
        private let firstLabel = UILabel()
        private let secondLabel = UILabel()
        private let thirdLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.35)

            tipsView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.88)
            tipsView.layer.cornerRadius = 6
            tipsView.layer.masksToBounds = true
            addSubview(tipsView)

            firstLabel.text = lksLocalized("Creating File…")
            firstLabel.textColor = .white
            firstLabel.font = .boldSystemFont(ofSize: 14)
            firstLabel.textAlignment = .center
            firstLabel.numberOfLines = 0
            tipsView.addSubview(firstLabel)

            secondLabel.text = lksLocalized("May take 8 or more seconds according to the UI complexity.")
            secondLabel.textColor = UIColor(red: 173 / 255, green: 180 / 255, blue: 190 / 255, alpha: 1)
            secondLabel.font = .systemFont(ofSize: 12)
            secondLabel.textAlignment = .left
            secondLabel.numberOfLines = 0
            tipsView.addSubview(secondLabel)

            thirdLabel.text = lksLocalized("The file can be opend by Lookin.app in macOS.")
            thirdLabel.textColor = UIColor(red: 173 / 255, green: 180 / 255, blue: 190 / 255, alpha: 1)
            thirdLabel.font = .systemFont(ofSize: 12)
            thirdLabel.textAlignment = .center
            thirdLabel.numberOfLines = 0
            tipsView.addSubview(thirdLabel)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let insets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
            let maxLabelWidth = bounds.width * 0.8 - insets.left - insets.right

            let firstSize = firstLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
            let secondSize = secondLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
            let thirdSize = thirdLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))

            let tipsWidth = max(firstSize.width, secondSize.width, thirdSize.width) + insets.left + insets.right

            firstLabel.frame = CGRect(
                x: tipsWidth / 2 - firstSize.width / 2,
                y: insets.top,
                width: firstSize.width,
                height: firstSize.height
            )
            secondLabel.frame = CGRect(
                x: tipsWidth / 2 - secondSize.width / 2,
                y: firstLabel.frame.maxY + 10,
                width: secondSize.width,
                height: secondSize.height
            )
            thirdLabel.frame = CGRect(
                x: tipsWidth / 2 - thirdSize.width / 2,
                y: secondLabel.frame.maxY + 5,
                width: thirdSize.width,
                height: thirdSize.height
            )

            let height = thirdLabel.frame.maxY + insets.bottom
            tipsView.frame = CGRect(
                x: bounds.width / 2 - tipsWidth / 2,
                y: bounds.height / 2 - height / 2,
                width: tipsWidth,
                height: height
            )
        }
    }
    #endif

    private enum SharedStorage {
        static let instance = LKS_ExportManager()
    }
}

#endif
