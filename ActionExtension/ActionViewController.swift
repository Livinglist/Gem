import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    let hostAppBundleIdentifier = "com.jiaqi.gem"
    let urlContentType = UTType.url.identifier
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    handleUrl(content: content, attachment: attachment, index: index)
                }
            }
        }
    }
    
    private func handleUrl(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: urlContentType) { [weak self] data, error in
            if error == nil, let item = data as? URL, let this = self {
                this.redirectToHostApp(item)
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func dismissWithError() {
        let alert = UIAlertController(title: "Error", message: "Error loading data", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func redirectToHostApp(_ item: URL) {
        let url = URL(string: "gem://\(item)")
        var responder = self as UIResponder?
        
        while (responder != nil) {
            if let application = responder as? UIApplication,
               let url {
                application.open(url)
            }
            
            responder = responder!.next
        }
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }
    
}
