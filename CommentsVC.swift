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

class CommentsVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var post:Post!
    var postHeight:CGFloat!
    var ref:FIRDatabaseReference!
    
    var tableView = UITableView()
    var backButton = UIButton()
    var topView = UIView()
    var titleLabel = UILabel()
    var posts:[Post] = []
    var typingBar:TypingBar!
    var commentsView: CommentsView!
    var commentsViewOriginY:CGFloat{
        return tableView.frame.maxY + 5
    }
    
    
    var dismissKeyboardRec:UITapGestureRecognizer!

    // set up table view and top bar. Get data from firebase.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        dismissKeyboardRec = UITapGestureRecognizer(target: self, action: #selector(CommentsVC.dismissKeyboard(_:)))
        view.addGestureRecognizer(dismissKeyboardRec)
        dismissKeyboardRec.isEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsVC.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        view.backgroundColor = UIColor.white
        setUpTopView()
        setUpTableView()
        setUpView()
        setUpTypingBar()
        posts.append(post)
        tableView.reloadData()
        for comment in post.comments{
        commentsView.addComment(comment)
        }
        commentsView.sortAndReload()
    }
    
    func setUpView(){
        commentsView = CommentsView(size: CGSize(width: view.frame.width - 20, height: view.frame.height - commentsViewOriginY - TypingBar.Height))
        commentsView.someDelegate = self
        commentsView.frame.origin.y = commentsViewOriginY
        commentsView.center.x = view.frame.width/2
        view.addSubview(commentsView)

    }
    
    func setUpTypingBar(){
        
        typingBar = TypingBar(width: view.frame.width, placeholder: "Add comment...", color: post.emotion.color,buttonText:"Send")
        typingBar.frame.origin.y = view.frame.height - typingBar.frame.height
        view.addSubview(typingBar)
        view.bringSubview(toFront: typingBar)
        typingBar.sendButton.addTarget(self, action: #selector(CommentsVC.postButtonAction), for: .touchUpInside)
        typingBar.textView.tintColor = UIColor.black
    }
    
    func postButtonAction(){
        let commentText = typingBar.textView.text
        if (commentText?.isEmpty)!{return}
        if commentText == typingBar.placeholder{return}
        let someString = NSString(string: commentText!)
        let ref = FIRDatabase.database().reference()
        let key = ref.childByAutoId().key
        
        let comment = Comment()
        comment.sender = GlobalData.You
        comment.text = someString as String
        comment.time = Date().timeIntervalSince1970*1000
        
        self.typingBar.sendButtonAction()
        self.dismissKeyboard()
        typingBar.resetToPlaceholder()

            ref.child("Posts").child(post.ID).child("Comments").child(key).setValue([
                "Sender Alias":GlobalData.You.alias,
                "Sender ID":userUID,
                "Time":FIRServerValue.timestamp(),
                "Text":someString,

                ])

        
        //change your update object
        post.comments.append(comment)
        
        commentsView.addComment(comment)
        commentsView.sortAndReload()
        tableView.reloadData()
    }
    
    //create the table view. Set the delegate and the cell it will use. set its frame. format it.
    func setUpTableView(){
        let originY = topView.frame.maxY
        tableView.frame = CGRect(x: 0, y: originY, width: view.frame.size.width - 20, height: postHeight)
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName:"PostCell",bundle:nil), forCellReuseIdentifier: "cell")
        tableView.center.x = view.frame.width/2
        
        view.addSubview(tableView)
        tableView.estimatedRowHeight = 20
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
        topView.backgroundColor = UIColor(white: 0.94, alpha: 1)
        
        backButton.frame.size = size
        backButton.setImage(#imageLiteral(resourceName: "leftArrowIcon"), for: .normal)
        backButton.contentEdgeInsets = inset
        backButton.addTarget(self, action: #selector(CommentsVC.backAction), for: .touchUpInside)
        
        topView.addSubview(backButton)
        backButton.changeToColor(UIColor.black)
        backButton.frame.origin.y = topView.frame.height - backButton.frame.height
        backButton.frame.origin.x = 0
        
        titleLabel.font = Font.PageHeaderSmall()
        titleLabel.text = "Post"
        titleLabel.textColor = UIColor.black
        titleLabel.sizeToFit()
        titleLabel.center.x = topView.frame.width/2
        titleLabel.center.y = backButton.center.y
        topView.addSubview(titleLabel)
        
        Draw.createLineUnderView(topView, color: UIColor.black,width:0.3)
    }
    
    //function called by the back button. Dismiss the view controller
    func backAction(){
        dismiss(animated: true, completion: nil)
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

extension CommentsVC:CommentsViewDelegate{
    
    func commentDeleted(comment: Comment) {
        ref.child("Posts").child(post.ID).child("Comments").child(comment.ID).setValue(nil)
        if let index = post.comments.index(where: {$0.ID == comment.ID}){
            post.comments.remove(at: index)
        }
        if let index2 = commentsView.comments.index(where: {$0.ID == comment.ID}){
            commentsView.comments.remove(at: index2)
        }
        commentsView.reloadData()
        tableView.reloadData()
    }
    func keyboardWillShow(_ notification: Notification) {
        let keyboardSize = ((notification as NSNotification).userInfo![UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        
        //move the bar up
        typingBar.frame.origin.y = view.frame.height - keyboardSize!.height - typingBar.frame.height
        dismissKeyboardRec.isEnabled = true
        commentsView.frame.size.height = view.frame.height - commentsViewOriginY - keyboardSize!.height - typingBar.frame.height
    }
    
    
    func keyboardWillHide(_ notification: Notification) {
        
        typingBar.frame.origin.y = view.frame.height - typingBar.frame.height
        commentsView.frame.size.height = view.frame.height - commentsViewOriginY - typingBar.frame.height
    }
    
    func dismissKeyboard(_ rec:UITapGestureRecognizer){
        if !typingBar.frame.contains(rec.location(in: view)){
            
            dismissKeyboard()
        }
    }
    
    func dismissKeyboard(){
        typingBar.textView.endEditing(true)
        dismissKeyboardRec.isEnabled = false
        
    }
}


