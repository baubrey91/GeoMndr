//
//  ViewController.swift
//  GeoMndr
//
//  Created by Brandon on 6/2/17.
//  Copyright © 2017 BrandonAubrey. All rights reserved.
//

import UIKit
import ContextMenu_iOS

let menuCellIdentifier = "rotationCell"
    
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, YALContextMenuTableViewDelegate {
    
    var menuTitles: [String?] = []
    var menuIcons: [UIImage?] = []
    var contextMenuTableView: YALContextMenuTableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initiateMenuOptions()
        //self.navigationController?.setValue(YALNavigationBar(), forKeyPath: "navigationBar")
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.contextMenuTableView!.reloadData()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration:duration)
        
        self.contextMenuTableView!.updateAlongsideRotation()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.contextMenuTableView!.reloadData()
        })
        
        self.contextMenuTableView!.updateAlongsideRotation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addSegue" {
            let navController = segue.destination as! UINavigationController
            let addView = navController.topViewController as! AddReminderViewController
            addView.GeoMndrDelegate = self
        }
    }
    
    @IBAction func presentMenuButtonTapped(_ sender: UIBarButtonItem) {
        
        // init YALContextMenuTableView tableView
        self.contextMenuTableView = YALContextMenuTableView(tableViewDelegateDataSource: self)
        self.contextMenuTableView!.animationDuration = 0.11;
        //optional - implement custom YALContextMenuTableView custom protocol
        self.contextMenuTableView!.yalDelegate = self
        let cellNib = UINib(nibName: "ContextMenuCell", bundle: nil)
        self.contextMenuTableView?.register(cellNib, forCellReuseIdentifier: menuCellIdentifier)
        
        // it is better to use this method only for proper animation
        self.contextMenuTableView?.show(in: self.navigationController!.view, with: UIEdgeInsets.zero, animated: true)
    }
    
    func contextMenuTableView(_ contextMenuTableView: YALContextMenuTableView!, didDismissWith indexPath: IndexPath!) {
        print("Menu dismissed with indexpath = \(indexPath)")
        switch indexPath.row {
        case 1:
            self.performSegue(withIdentifier: "addSegue", sender: self)
            //add delegate here
        default:
            break
            //dismiss
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let t = tableView as! YALContextMenuTableView
        t.dismis(with: indexPath)
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuTitles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let t = tableView as! YALContextMenuTableView
        let cell = t.dequeueReusableCell(withIdentifier: menuCellIdentifier, for:indexPath) as! ContextMenuCell
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.backgroundColor = UIColor.clear
        cell.menuTitleLabel.text = self.menuTitles[indexPath.row]
        cell.menuImageView.image = self.menuIcons[indexPath.row]
        
        
        return cell;
    }
    
    func initiateMenuOptions() {
        self.menuTitles = ["",
                           "Add new",
                           "Map",
                           "About",
                           "Add to favourites",
                           "Block user"]
        
        self.menuIcons = [UIImage(named: "Icnclose"), UIImage(named: "add_icon"), UIImage(named: "LikeIcn"), UIImage(named: "AddToFriendsIcn"), UIImage(named: "AddToFavouritesIcn"), UIImage(named: "BlockUserIcn")]
    }
}

extension ViewController: GeoMndrProtocol {
    func addGeoMndr() {

    }
}

