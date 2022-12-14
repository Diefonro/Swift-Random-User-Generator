//
//  ViewController.swift
//  Random User Generator
//
//  Created by Andrés Fonseca on 18/08/2022.
//

import UIKit
import Kingfisher

class TableVC: UIViewController {
    
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var segmentedControlFilter: UISegmentedControl?
    @IBOutlet var removeFilterBtnView: UIView?
    @IBOutlet var refreshBtnView: UIView?
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView?
    
    var users: [User] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var refreshControl = UIRefreshControl()
    var buttonIsActive = false
    var refreshWasTapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.isUserInteractionEnabled = true
        refreshControl.addTarget(self, action: #selector(swipedDownToRefresh), for: UIControl.Event.valueChanged)
        tableView?.addSubview(refreshControl)
        
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        activityIndicatorView?.startAnimating()
        retrieveUsers()
        removeFilterBtnView?.layer.cornerRadius = 6
        refreshBtnView?.layer.cornerRadius = 50
        activityIndicatorView?.hidesWhenStopped = true
        
    }
    
    @objc func swipedDownToRefresh(_ sender: UIRefreshControl){
        DispatchQueue.main.async {
            self.retrieveUsers()
            self.activityIndicatorView?.isHidden = true
            self.tableView?.reloadData()
            self.refreshControl.endRefreshing()
        }
        
    }
    
    func setKeys(){
        UserDefaults.standard.set("Base endpoint was saved", forKey: APIRequest.shared.url)
        UserDefaults.standard.set("Male endpoint was saved", forKey: APIRequest.shared.urlMale)
        UserDefaults.standard.set("Female endpoint was saved", forKey: APIRequest.shared.urlFemale)
        UserDefaults.standard.synchronize()
    }
    
    // Se recupera el valor ya guardado
    func getKeys(){
        if let valueBase = UserDefaults.standard.string(forKey: APIRequest.shared.url), let valueFemale = UserDefaults.standard.string(forKey: APIRequest.shared.urlFemale), let valueMale = UserDefaults.standard.string(forKey: APIRequest.shared.urlMale){
            print("Data was saved correclty, keys are: \(valueBase), \(valueFemale) y \(valueMale)")
        } else {
            print("There's no data saved")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    func retrieveUsers(){
        
        self.activityIndicatorView?.startAnimating()
        
        APIRequest.shared.retrieveUsers { user in
            self.activityIndicatorView?.stopAnimating()
            if let users = user {
                self.users = users
            }
        } failure: { error in
            self.activityIndicatorView?.stopAnimating()
            self.showAlert()
        }
        
    }
    
    func showAlert(){
        if APIRequest.shared.apiError {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "API not working", message: "Please tap on refresh button to try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    switch action.style{
                    case .default:
                        print("default")
                    case .cancel:
                        print("cancel")
                    case .destructive:
                        print("destructive")
                    default:
                        print("Unknown error")
                        
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    @IBAction func refreshViewBtn(_ sender: Any) {
        retrieveUsers()
        refreshWasTapped = true
        if refreshWasTapped {
            UIView.animate(withDuration: 0.25) {
                self.refreshBtnView?.backgroundColor = .systemGray4
                self.refreshBtnView?.backgroundColor = .clear
                self.refreshWasTapped = false
            }
        }
    }
    
    @IBAction func segmentedControlAction(_ sender: Any) {
        switch segmentedControlFilter?.selectedSegmentIndex{
        case 0:
            activityIndicatorView?.startAnimating()
            APIRequest.shared.url = APIRequest.shared.urlMale
            retrieveUsers()
        case 1:
            activityIndicatorView?.startAnimating()
            APIRequest.shared.url = APIRequest.shared.urlFemale
            retrieveUsers()
        default: print("Unknown segment")
        }
    }
    
    @IBAction func btnRemoveFilter(_ sender: Any) {
        activityIndicatorView?.startAnimating()
        APIRequest.shared.url = APIRequest.shared.urlAfterFilter
        retrieveUsers()
        buttonIsActive = true
        if buttonIsActive {
            UIView.animate(withDuration: 0.25) {
                self.removeFilterBtnView?.backgroundColor = .systemGray4
                self.removeFilterBtnView?.backgroundColor = .systemGray6
                self.buttonIsActive = false
            }
        }
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PersonDetailSegue"{
            guard let personDetailVC = segue.destination as? PersonDetailVC else { return }
            guard let indexPath = tableView?.indexPathForSelectedRow else { return }
            let user = users[indexPath.row]
            personDetailVC.user = user
        }
    }
    
    
}

extension TableVC: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "PersonDetailSegue", sender: self)
        retrieveUsers()
        
    }
}

extension TableVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let customCell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as? CustomTableViewCell
        let person = users[indexPath.row]
        customCell?.lblPersonName?.text = "\(person.name?.first ?? "") \(person.name?.last ?? "")"
        customCell?.personImageView?.kf.setImage(with: URL(string: person.picture?.thumbnail ?? ""))
        customCell?.personImageView?.layer.cornerRadius = 25
        return customCell!
    }
    
    
}

