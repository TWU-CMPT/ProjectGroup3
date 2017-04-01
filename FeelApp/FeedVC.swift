//FeelApp
//This is the Feed view controller. For the user to view posts from other users in a newsfeed format. Anyonmous posts, identified only by the user's alias.
///Programmers: Deepak and Carson
//Version 1: Created tableview with PostCell and test data.
//Version 2: Connected to database.
//Version 3: Improved UI. Set fonts and colors for each story. Created title bar.
//Version 4: Fixed bug where long text was overflowing to the right, instead of increasing the height of the cell.

//Coding standard:
//all view controller files have a descriptor followed by "VC."
//all view files have a descriptor folled by "view"


import UIKit
import FirebaseDatabase

class FeedVC: UIViewController,UITableViewDelegate,UITableViewDataSource {

    var ref:FIRDatabaseReference!
    
    var tableView = UITableView()
    var backButton = UIButton()
    var topView = UIView()
    var titleLabel = UILabel()
    var posts:[Post] = []
    var notificationButton = UIButton()
    
    override var preferredStatusBarStyle: UIStatusBarStyle{return UIStatusBarStyle.lightContent}
    
    // set up table view and top bar. Get data from firebase.
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = FIRDatabase.database().reference()
        view.backgroundColor = UIColor.white
        setUpTopView()
        setUpTableView()
        getPosts()
    }
    
    //create the table view. Set the delegate and the cell it will use. set its frame. format it.
    func setUpTableView(){
        let originY = topView.frame.maxY
        tableView.frame = CGRect(x: 0, y: originY, width: view.frame.size.width - 20, height: view.frame.size.height - originY)
        //tableView.frame.origin.y = getPosts().frame.maxY + 40
        tableView.tableFooterView = UIView()
        tableView.center.x = view.frame.width/2
        tableView.register(UINib(nibName:"PostCell",bundle:nil), forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorColor = globalLightGrey
        
        tableView.bounces = true
        tableView.alwaysBounceVertical = true
        tableView.showsVerticalScrollIndicator = false
        
    }
    
    //Set up the top bar. The view, back button, and title label.
    func setUpTopView(){
        let size = CGSize(width: 50, height: 50)
        let inset = UIEdgeInsets(top: 13, left: 13, bottom: 13, right: 13)
        
        topView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: view.frame.width, height: 70))
        view.addSubview(topView)
        topView.backgroundColor = nowColor
        
        backButton.frame.size = size
        backButton.setImage(#imageLiteral(resourceName: "leftArrowIcon"), for: .normal)
        backButton.contentEdgeInsets = inset
        backButton.addTarget(self, action: #selector(FeedVC.backAction), for: .touchUpInside)
        
        topView.addSubview(backButton)
        backButton.changeToColor(UIColor.white)
        backButton.frame.origin.y = topView.frame.height - backButton.frame.height
        backButton.frame.origin.x = 0
        
        titleLabel.font = Font.PageHeaderSmall()
        titleLabel.text = "Feed"
        titleLabel.textColor = UIColor.white
        titleLabel.sizeToFit()
        titleLabel.center.x = topView.frame.width/2
        titleLabel.center.y = backButton.center.y
        topView.addSubview(titleLabel)
        
        notificationButton.frame.size = size
        notificationButton.setImage(#imageLiteral(resourceName: "notificationIcon.png"), for: .normal)
        notificationButton.contentEdgeInsets = inset
        topView.addSubview(notificationButton)
        notificationButton.changeToColor(UIColor.white)
        notificationButton.frame.origin.y = topView.frame.height - notificationButton.frame.height
        notificationButton.frame.origin.x = view.frame.width - notificationButton.frame.width
        notificationButton.addTarget(self, action: #selector(FeedVC.toNotifications), for: .touchUpInside)
        
    }
    
    func toNotifications(){
        let vc = NotificationsVC()
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }
    
    //function called by the back button. Dismiss the view controller
    func backAction(){
        dismiss(animated: true, completion: nil)
    }
    
    //Get the data from firebase. Add it to the posts array. then reload the tableview
    func getPosts(){
        
        ref.child("Posts").observeSingleEvent(of: .value, with: {allSnap in
            let hello = userUID
            let dict = allSnap.value as? [String:AnyObject] ?? [:]
            
            for (id,postDict) in dict{
                
                let post = Post()
                
                let emotionDict = postDict["Emotion"] as? [String:AnyObject] ?? [:]
                let type = emotionDict["Type"] as? String ?? ""
                post.emotion = Emotion.fromString(type)
                post.emotion.text = emotionDict["Text"] as? String ?? ""
                post.emotion.time = emotionDict["Time"] as? TimeInterval ?? TimeInterval()
                post.ID = id
                post.sender.id = postDict["Sender ID"] as? String ?? ""
                post.sender.alias = postDict["Sender Alias"] as? String ?? ""
                
                let likeDict = postDict["Likes"] as? [String:Bool] ?? [:]
                for (someID,_) in likeDict{
                    post.likes.append(someID)
                }
                
                let allCommentDict = postDict["Comments"] as? [String:AnyObject] ?? [:]

                for (id,_) in postDict["Reports"] as? [String:AnyObject] ?? [:]{
                    post.reports.append(id)
                    break
                    
                }

                
                
                for (someID,commentDict) in allCommentDict{
                    let comment = Comment()
                    let person = Person()
                    person.alias = commentDict["Sender Alias"] as? String ?? ""
                    person.id = commentDict["Sender ID"] as? String ?? ""
                    comment.sender = person
                    comment.text = commentDict["Text"] as? String ?? ""
                    comment.time = commentDict["Time"] as? TimeInterval ?? TimeInterval()
                    post.comments.append(comment)
                }
                
                var cantSee = false
                for (id,_) in postDict["Cant See"] as? [String:AnyObject] ?? [:]{
                    if id == userUID{
                        cantSee = true
                        break
                    }
                }
                
                if !cantSee{
                self.posts.append(post)
                }

            }
            self.posts.sort(by: {$0.emotion.time > $1.emotion.time})
            self.tableView.reloadData()
        })
    }
    
    
    //tableview data source method. say the number of rows that will appear
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    //tableview data source method. set and format the cell. 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! PostCell
        cell.setUp(post: posts[indexPath.row])
        cell.selectionStyle = .none
        let rec = UITapGestureRecognizer(target: self, action: #selector(FeedVC.likeViewClicked(sender:)))
        cell.likeView.addGestureRecognizer(rec)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = CommentsVC()
        vc.post = posts[indexPath.item]
        vc.postHeight = tableView.rectForRow(at: indexPath).height
        present(vc, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let post = posts[indexPath.item]
        
        var reportAction = UITableViewRowAction(style: .normal, title: "Report") { action, index in self.reportPost(post:post)}
        reportAction.backgroundColor = UIColor(white: 0.7, alpha: 1)
        var deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { action, index in self.deletePost(post:post,yours:true)}
        var hideAction = UITableViewRowAction(style: .normal, title: "Hide") { action, index in self.deletePost(post:post,yours:false)}
        deleteAction.backgroundColor = UIColor(white: 0.6, alpha: 1)
        hideAction.backgroundColor = UIColor(white: 0.6, alpha: 1)
        if post.sender.id == userUID{
        
            return [deleteAction]
        }
        else{
            if post.reports.contains(userUID){
            return [hideAction]
            }
            else{
                return [hideAction,reportAction]
            }
        }

    }
    
    func reportPost(post:Post){

        ref.child("Posts").child(post.ID).child("Reports").observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.childrenCount >= 4{
                 self.ref.child("Posts").child(post.ID).child("Reports").setValue(nil)
            }
            else{
                self.ref.child("Posts").child(post.ID).child("Reports").child(userUID).setValue(true)
            }
        })
        
        let alert = UIAlertController(title: "Report", message: "Thank you for reporting this post. We are sorry you had this experience.", preferredStyle: .alert) // 7
        let defaultAction = UIAlertAction(title: "Hide Post", style: .cancel) { (alert: UIAlertAction!) -> Void in
            
            self.deletePost(post: post, yours: false)
        }
        let closeAction = UIAlertAction(title: "Close", style: .default) { (alerta: UIAlertAction!) -> Void in
            
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(defaultAction) // 9
        alert.addAction(closeAction)
        present(alert, animated: true, completion:nil)  // 11

        
        post.reports.append(userUID)
        tableView.reloadData()
        
    }
    
    func deletePost(post:Post,yours:Bool){
        if yours{
            ref.child("Posts").child(post.ID).setValue(nil)
            
        }
        else{
            ref.child("Posts").child(post.ID).child("Cant See").child(userUID).setValue(true)
        }
        let index = posts.index(where: {$0.ID == post.ID})!
        posts.remove(at: index)
        tableView.reloadData()
    }
    
    func likeViewClicked(sender:UITapGestureRecognizer){
        var view = sender.view!
        while !(view is PostCell){
            view = view.superview!
        }
        let post = (view as! PostCell).post!
        
        if post.likes.contains(userUID){
            let index = post.likes.index(of: userUID)!
            post.likes.remove(at: index)
        }
        else{
            post.likes.append(userUID)
        }
        
        ref.child("Posts").child(post.ID).child("Likes").child(userUID).observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.exists(){
                self.ref.child("Posts").child(post.ID).child("Likes").child(userUID).setValue(nil)
            }
            else{
                self.ref.child("Posts").child(post.ID).child("Likes").child(userUID).setValue(true)
            }
        })
        
        tableView.reloadData()
    
    
    }
}
