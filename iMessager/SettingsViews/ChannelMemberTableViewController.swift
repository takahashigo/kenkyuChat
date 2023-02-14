//
//  ChannelMemberTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/08.
//

import UIKit

protocol updateChannelMemberIds {
    func updateMemberIds(memberIds: [String]) -> Void
}

class ChannelMemberTableViewController: UITableViewController {

    // MARK: - Vars
    var allUsers: [User] = []
    var memberIds: [String]?
    var delegate: updateChannelMemberIds?
    var isDetail = false
    
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        loadAllUsers()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let user = allUsers[indexPath.row]
        cell.textLabel?.text = user.username
        
        cell.accessoryType = memberIds!.contains(user.id) ? .checkmark : .none

        return cell
    }

    
    // MARK: - Table view delegates
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        updateCellCheck(indexPath)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "tableviewBackgroundColor")
        return headerView
        
    }
    
    
    // MARK: - LoadingChannelMembers
    private func loadAllUsers() {
        FirebaseUserListener.shared.downloadAllUsersFromFirebase { allUsers in
            self.allUsers = allUsers
            
            self.tableView.reloadData()
        }
    }
    
    private func updateCellCheck(_ indexPath: IndexPath) {
        if !isDetail {
            if self.memberIds!.contains(allUsers[indexPath.row].id) {
                if let index = memberIds!.firstIndex(of: allUsers[indexPath.row].id) {
                    self.memberIds?.remove(at: index)
                }
            } else {
                self.memberIds!.append(allUsers[indexPath.row].id)
            }
            
            delegate?.updateMemberIds(memberIds: self.memberIds!)
        }
        
    }
    

}
