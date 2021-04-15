//
//  ProjectManager - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

class ViewController: UIViewController {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    private let todoCollectionView = ListCollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout(), collectionType: .todo)
    private let doingCollectionView = ListCollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout(), collectionType: .doing)
    private let doneCollectionView = ListCollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout(), collectionType: .done)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigation()
        stackView.frame = view.bounds
        view.addSubview(stackView)
        collectionViewSetup()
    }
    
    private func setNavigation() {
        navigationItem.title = "Project Manager"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(presentPopOverViewController))
    }
    
    private func collectionViewSetup() {
        stackView.addArrangedSubview(todoCollectionView)
        stackView.addArrangedSubview(doingCollectionView)
        stackView.addArrangedSubview(doneCollectionView)
        
        todoCollectionView.delegate = self
        doingCollectionView.delegate = self
        doneCollectionView.delegate = self
        todoCollectionView.dragDelegate = self
        todoCollectionView.dropDelegate = self
        doingCollectionView.dragDelegate = self
        doingCollectionView.dropDelegate = self
        doneCollectionView.dragDelegate = self
        doneCollectionView.dropDelegate = self
        todoCollectionView.dragInteractionEnabled = true
        doingCollectionView.dragInteractionEnabled = true
        doneCollectionView.dragInteractionEnabled = true
    }
    
    @objc private func presentPopOverViewController() {
        didTapAddButton(with: todoCollectionView)
    }
    
    private func deleteFromBefore(thing: Thing) {
        switch thing.state {
        case .todo:
            todoCollectionView.deleteDataSource(thing: thing)
        case .doing:
            doingCollectionView.deleteDataSource(thing: thing)
        case .done:
            doneCollectionView.deleteDataSource(thing: thing)
        default:
            return
        }
    }
}

//MARK: - Thing Add / Edit 관련
extension ViewController {
    private func didTapAddButton(with collectionView: ListCollectionView) {
        let popOverViewController = PopOverViewController(collectionView: collectionView, leftBarbuttonTitle: PopOverNavigationItems.cancelButton, indexPath: nil)
        popOverViewController.modalPresentationStyle = .formSheet
        self.present(UINavigationController(rootViewController: popOverViewController), animated: true, completion: nil)
    }

    private func configurePopOverView(_ collectionView: ListCollectionView, indexPath: IndexPath) -> UINavigationController? {
        let popOverViewController = UINavigationController(rootViewController: PopOverViewController(collectionView: collectionView, leftBarbuttonTitle: PopOverNavigationItems.editButton, indexPath: indexPath))

        guard let presentedContentView = popOverViewController.viewControllers.last as? PopOverViewController else { return nil }

        guard let thing = collectionView.diffableDataSource.itemIdentifier(for: indexPath) else { return nil }

        presentedContentView.textField.text = thing.title
        guard let dueDate = thing.dueDate else { return nil }
        presentedContentView.datePicker.date = Date(timeIntervalSince1970: dueDate)
        presentedContentView.textView.text = thing.des

        presentedContentView.textField.isUserInteractionEnabled = false
        presentedContentView.datePicker.isUserInteractionEnabled = false
        presentedContentView.textView.isUserInteractionEnabled = false
        return popOverViewController
    }
}

//MARK: - UICollectionViewDragDelegate -
extension ViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let collectionView = collectionView as? ListCollectionView,
              let thing = collectionView.diffableDataSource.itemIdentifier(for: indexPath) else {
            return []
        }
        
        let itemProvider = NSItemProvider(object: thing)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        
        return [dragItem]
    }
}

//MARK: - UICollectionViewDropDelegate -
extension ViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        var dropProposal = UICollectionViewDropProposal(operation: .cancel)
        guard session.items.count == 1 else {
            return dropProposal
        }
        if collectionView.hasActiveDrag {
            dropProposal = UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            dropProposal = UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
        return dropProposal
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let collectionView = collectionView as? ListCollectionView else {
            return
        }
        
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = collectionView.numberOfSections - 1
            let row = collectionView.numberOfItems(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        coordinator.session.loadObjects(ofClass: Thing.self) { [weak self] (items) in
            guard let self = self else { return }
            guard let thingItem = items as? [Thing],
                  let thing = thingItem.first else { return }
            let state = collectionView.collectionType
            
            self.deleteFromBefore(thing: thing)
            thing.state = state
            collectionView.reorderDataSource(destinationIndexPath: destinationIndexPath, thing: thing)

        }
    }
}

//MARK: - UICollectionViewDelegate -
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let collectionView = collectionView as? ListCollectionView,
              let popOverViewController = configurePopOverView(collectionView, indexPath: indexPath) else { return }
        self.present(popOverViewController, animated: true)
    }
}
