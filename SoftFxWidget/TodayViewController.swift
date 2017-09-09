//
//  TodayViewController.swift
//  SoftFxWidget
//
//  Created by Macbook on 09.09.17.
//  Copyright © 2017 Macbook. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateWidget()
    }
    
    private func getDate() -> String {
        let defaults = UserDefaults(suiteName: "group.TodayExtensionDate")
        defaults?.synchronize()
        return String(describing: defaults!.object(forKey: "lastUpdate") ?? "Дата не найдена")
    }
    
    func updateWidget(){
        
        DispatchQueue.main.async {
            self.dateLabel.text = self.getDate()
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {

        updateWidget()
        completionHandler(NCUpdateResult.newData)
    }
    
    //MARK: - Actions
    
    @IBAction func openApp(_ sender: UIButton) {
        let url = URL(string:"testSoftFx://")
        self.extensionContext?.open(url!, completionHandler: nil)
    }
    
}
