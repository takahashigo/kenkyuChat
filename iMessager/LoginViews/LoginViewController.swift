//
//  LoginViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/26.
//

import UIKit
import ProgressHUD


class LoginViewController: UIViewController {
    
    // MARK: - labels
    
    @IBOutlet weak var titleLabelOutlet: UILabel!
    @IBOutlet weak var emailLabelOutlet: UILabel!
    @IBOutlet weak var passwordLabelOutlet: UILabel!
    @IBOutlet weak var repeatPasswordLabelOutlet: UILabel!
    @IBOutlet weak var signUpLabel: UILabel!
    
    // MARK: - textfields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    // MARK: - buttons
    @IBOutlet weak var loginButtonOutlet: UIButton!
    @IBOutlet weak var signUpButtonOutlet: UIButton!
    @IBOutlet weak var resendEmailButtonOutlet: UIButton!
    
    // MARK: - views
    @IBOutlet weak var repeatPasswordLineView: UIView!
    
    // MARK: - toggle
    var isLogin = true
    
    
    
    // MARK: - life cycle method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITabBar.appearance().tintColor = .black
        
        setupBackgroundTap()
        updateUIFor(login: true)
        setupTextFieldDelegates()
    }
    
    
    // MARK: - IBActions
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if isDataInputedFor(type: isLogin ? "login" : "register") {
            isLogin ? loginUser() : registerUser()
        } else {
            ProgressHUD.showFailed("全ての項目に入力してください")
        }
    }
    
    @IBAction func forgotPasswordButtonPressed(_ sender: UIButton) {
        if isDataInputedFor(type: "password") {
            // reset password
            resetPassword()
        } else {
            ProgressHUD.showFailed("メールアドレスを入力してください")
        }
    }
    
    @IBAction func resendEmailButtonPressed(_ sender: UIButton) {
        if isDataInputedFor(type: "password") {
            // resend Verification email
            resendVerificationEmail()
        } else {
            ProgressHUD.showFailed("メールアドレスを入力してください")
        }
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        updateUIFor(login: sender.titleLabel?.text == "ログイン")
        isLogin.toggle()
//        isLogin ?
    }
    
    
    // MARK: - setup
    private func setupTextFieldDelegates() {
        emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        repeatPasswordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updatePlaceholderLabels(textfield: textField)
    }
    
    // MARK: - setup(KeyBoard)
    private func setupBackgroundTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func backgroundTap() {
        view.endEditing(false)
    }
    

    // MARK: - Animations
    private func updateUIFor(login: Bool) {
        titleLabelOutlet.text = login ? "ログイン" : "新規登録"
        loginButtonOutlet.setImage(UIImage(named: login ? "loginBtn" : "registerBtn"), for: .normal)
        signUpButtonOutlet.setTitle(login ? "新規登録" : "ログイン", for: .normal)
        
        signUpLabel.text = login ? "アカウントをお持ちでない方はこちら" : "アカウントをお持ちの方はこちら"
        
        UIView.animate(withDuration: 0.5) {
            self.repeatPasswordTextField.isHidden = login
            self.repeatPasswordLabelOutlet.isHidden = login
            self.repeatPasswordLineView.isHidden = login
        }
    }
    
    private func updatePlaceholderLabels(textfield: UITextField) {
        switch textfield {
        case emailTextField:
            emailLabelOutlet.text = textfield.hasText ? "メールアドレス" : ""
        case passwordTextField:
            passwordLabelOutlet.text = textfield.hasText ? "パスワード" : ""
        default:
            repeatPasswordLabelOutlet.text = textfield.hasText ? "確認用パスワード" : ""
        }
    }
    
    
    // MARK: - Helpers
    private func isDataInputedFor(type: String) -> Bool {
        switch type {
        case "login":
            return emailTextField.text != "" && passwordTextField.text != ""
        case "register":
            return emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != ""
        default:
            return emailTextField.text != ""
        }
    }
    
    private func loginUser() {
        FirebaseUserListener.shared.loginUserWithEmail(email: emailTextField.text!, password: passwordTextField.text!) { (error, isEmailVerified) in
            if error == nil {
                if isEmailVerified {
                    
                    self.goToApp()
                } else {
                    ProgressHUD.showFailed("メールアドレスを確認してください")
                    self.resendEmailButtonOutlet.isHidden = false
                }
            } else {
//                ProgressHUD.showFailed(error?.localizedDescription)
                ProgressHUD.showFailed("ログインに失敗しました")
            }
        }
    }
    
    private func registerUser() {
        if passwordTextField.text! == repeatPasswordTextField.text! {
            
            FirebaseUserListener.shared.registerUserWith(email: emailTextField.text!, password: passwordTextField.text!) { error in
                if error == nil {
                    ProgressHUD.showSuccess("確認メールを送信いたしました")
                    // ProgressHUD.showSuccess("新規登録に成功しました")
                    self.resendEmailButtonOutlet.isHidden = false
                    // maybe don't verify email, self.loginUser()
                    // self.loginUser()
                } else {
//                    ProgressHUD.showFailed(error!.localizedDescription)
                    ProgressHUD.showFailed("新規登録に失敗しました")
                }
            }
        } else {
            ProgressHUD.showFailed("パスワードが違います")
        }
    }
    
    private func resetPassword() {
        FirebaseUserListener.shared.resetPasswordFor(email: emailTextField.text!) { error in
            if error == nil {
                ProgressHUD.showSuccess("確認メールを送信いたしました")
            } else {
//                ProgressHUD.showFailed(error!.localizedDescription)
                ProgressHUD.showFailed("パスワードの再設定に失敗しました")
            }
        }
    }
    
    private func resendVerificationEmail() {
        FirebaseUserListener.shared.resendVerificationEmail(email: emailTextField.text!) { error in
            if error == nil {
                ProgressHUD.showSuccess("認証メールを送信いたしました")
            } else {
//                ProgressHUD.showFailed(error!.localizedDescription)
                ProgressHUD.showFailed("認証メールの送信に失敗しました")
            }
        }
    }
    
    
    
    // MARK: - Navigation
    private func goToApp() {
        let mainView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainView") as!
        UITabBarController
        
        mainView.modalPresentationStyle = .fullScreen
        self.present(mainView, animated: true, completion: nil)
        
    }
    
    
    
    
    
    
    
    
    
}

