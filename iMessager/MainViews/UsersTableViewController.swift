//
//  UsersTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/27.
//

import UIKit



class UsersTableViewController: UITableViewController, updateUsers {
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var userSegmentOutlet: UISegmentedControl!
    
    // MARK: - IBActions
    
    @IBAction func userSegmentValueChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    // MARK: - Vars
    var allUsers: [User] = []
    var blockedUsers: [User] = []
    var filteredUsers: [User] = []
    
    // MARK: - Lets
    let searchController = UISearchController(searchResultsController: nil)

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "研究員"
        
        self.refreshControl = UIRefreshControl()
        self.tableView.refreshControl = self.refreshControl
        
        
//        createDummyUsers()
        tableView.tableFooterView = UIView()
        setupSearchController()
        downloadUsers()
        downloadBlockedUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userSegmentOutlet.selectedSegmentIndex == 0 ?
               searchController.isActive ? filteredUsers.count : allUsers.count
                :
               searchController.isActive ? filteredUsers.count : blockedUsers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
        let user = userSegmentOutlet.selectedSegmentIndex == 0 ?
        searchController.isActive ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
        :
        searchController.isActive ? filteredUsers[indexPath.row] : blockedUsers[indexPath.row]
        
        cell.configure(user: user)
        
        return cell
    }
    
    
    // MARK: - Table View Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "tableviewBackgroundColor")
        
        return headerView
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let deleteButton: UITableViewRowAction = userSegmentOutlet.selectedSegmentIndex == 0 ?
        
        UITableViewRowAction(style: .normal, title: "ブロック") { (action, index) -> Void in
            var userToBlock = self.allUsers[indexPath.row]
            self.allUsers.remove(at: indexPath.row)
            
            var updateUser = User.currentUser!
            updateUser.blockList.append(userToBlock.id)
            
            saveUserLocally(updateUser)
            FirebaseUserListener.shared.saveUserToFirestore(updateUser)
            
            // リロード
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // ブロックユーザーをリフレッシュ
            self.downloadBlockedUsers()
        }
        :
        UITableViewRowAction(style: .normal, title: "ブロック解除") { (action, index) -> Void in
            var userToUnBlock = self.blockedUsers[indexPath.row]
            self.blockedUsers.remove(at: indexPath.row)
            
            var updateUser = User.currentUser!
            
            if let index = User.currentUser?.blockList.firstIndex(of: userToUnBlock.id) {
                updateUser.blockList.remove(at: index)
            }
            
            saveUserLocally(updateUser)
            FirebaseUserListener.shared.saveUserToFirestore(updateUser)
            
            
            // リロード
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // 全ユーザーをリフレッシュ
            self.downloadUsers()
        }
        
        
        deleteButton.backgroundColor = userSegmentOutlet.selectedSegmentIndex == 0 ? UIColor.red : UIColor.green

        return [deleteButton]
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // プロフィールに移動
        let user = userSegmentOutlet.selectedSegmentIndex == 0 ?
        searchController.isActive ? filteredUsers[indexPath.row] : allUsers[indexPath.row]
        :
        searchController.isActive ? filteredUsers[indexPath.row] : blockedUsers[indexPath.row]
        
        userSegmentOutlet.selectedSegmentIndex == 0 ? showUserProfile(user, false) : showUserProfile(user, true)
    }
    
    
    // MARK: - DownloadUsers
    func downloadUsers() {
        // 全てのユーザーを取得
        FirebaseUserListener.shared.downloadAllUsersFromFirebase { allFirebaseUsers in
            self.allUsers = allFirebaseUsers
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func downloadBlockedUsers() {
        
        FirebaseUserListener.shared.downloadBlockedUsersFromFirebase { allBlockedUsers in
            self.blockedUsers = allBlockedUsers
            print(self.blockedUsers)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    // MARK: - SetupSearchController
    private func setupSearchController() {
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "研究員を検索"
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        
    }
    
    private func filteredContentForSearchText(searchText: String) {
        filteredUsers = userSegmentOutlet.selectedSegmentIndex == 0 ?
                        allUsers.filter({ (user) -> Bool in
                            return user.username.lowercased().contains(searchText.lowercased())
                        })
                        :
                        blockedUsers.filter({ (user) -> Bool in
                            return user.username.lowercased().contains(searchText.lowercased())
                        })
        
        tableView.reloadData()
    }
    
    
    // MARK: - UIScrollViewDelegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if self.refreshControl!.isRefreshing {
            self.downloadUsers()
            self.downloadBlockedUsers()
            self.refreshControl!.endRefreshing()
        }
        
    }
    
    
    // MARK: - Navigation
    private func showUserProfile(_ user: User, _ isBlocked: Bool) {
        
        let profileView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ProfileView") as! ProfileTableViewController
        
        profileView.user = user
        profileView.isBlocked = isBlocked
        profileView.delegate = self
        self.navigationController?.pushViewController(profileView, animated: true)
        
    }
    
    
}


// MARK: - UISearchResultUpdating
extension UsersTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
