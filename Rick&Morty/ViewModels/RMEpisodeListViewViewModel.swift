//
//  RMEpisodeListViewViewModel.swift
//  Rick&Morty
//
//  Created by Dmytro Ivanenko on 17.01.2023.
//

import Foundation ///Test

protocol RMEpisodeListViewViewModelDelegate: AnyObject {
    
    func didLoadInitialEpisodes()
    
    func didLoadMoreEpisodes(with newIndexPaths: [IndexPath])
    
    func didSelectEpisode(_ episode: RMEpisode)
    
}

//View model to handle episode list view logic
final class RMEpisodeListViewViewModel: NSObject {
    
    
    public weak var delegate: RMEpisodeListViewViewModelDelegate?
    
    
    private var isLoadingMoreCharacters = false
    
    
    private var episodes: [RMEpisode] = [] {
        didSet {
            for episode in episodes {
//                let viewModel = RMEpisodeCollectionViewCellViewModel(
//                    characterName: character.name,
//                    characterStatus: character.status,
//                    characterImageUrl: URL(string: character.image)
//                )
                if !cellViewModels.contains(viewModel) {
                    cellViewModels.append(viewModel)
                }
            }
        }
    }
    
    
    private var cellViewModels: [RMCharacterEpisodeCollectionViewCellViewModel] = []
    
    
    private var appInfo: RMGetAllCharactersResponse.Info? = nil
    
    
    /// Fetch initial set of characters (20)
    public func fetchCharacter() {

        RMServise.shared.execute(
            .listCharactersRequets,
            expecting: RMGetAllCharactersResponse.self
        ) { [weak self] result in
            switch result {
            case .success(let responseModel):
                let results = responseModel.results
                let info = responseModel.info
                self?.characters = results
                self?.appInfo = info
                DispatchQueue.main.async {
                    self?.delegate?.didLoadInitialCharacter()
                }
            case .failure(let error):
                print(String(describing: error))
            }
        }
        
    }
    
    
    // Paginated if additional character is needed
    public func fetchAdditionalCharacters(url: URL) {
        
        guard !isLoadingMoreCharacters  else {
            return
        }
        
        isLoadingMoreCharacters = true
        guard let request = RMRequest(url: url) else {
            isLoadingMoreCharacters = false
            return
        }
        
        RMServise.shared.execute(request, expecting: RMGetAllCharactersResponse.self) { [weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            
            switch result {
                
            case .success(let responseModel):
                print("Pre update: \(strongSelf.cellViewModels.count)")
                let moreResults = responseModel.results
                let info = responseModel.info
                strongSelf.appInfo = info
                
                print(moreResults.count)
                //print(moreResults.first?.name)
                
                let originalCount = strongSelf.characters.count
                let newCount = moreResults.count
                let total = originalCount + newCount
                let startingIndex = total - newCount
                let indexPathToAdd: [IndexPath] = Array(startingIndex..<(startingIndex + newCount)).compactMap({
                    return IndexPath(row: $0, section: 0)
                })
                strongSelf.characters.append(contentsOf: moreResults)
                
                print("Post update: \(strongSelf.cellViewModels.count)")
              
                
                //MARK: - PROBLEM PLACE
                
                DispatchQueue.main.async {
                    strongSelf.delegate?.didLoadMoreCharacters(
                        with: indexPathToAdd
                    )
                    
                    strongSelf.isLoadingMoreCharacters = false
                }
                
            case .failure(let failure):
                print(String(describing: failure))
                self?.isLoadingMoreCharacters = false
            }
        }
        
    }
    
    
    public var shouldShowMoreIndicator: Bool {
        return appInfo?.next != nil
        
    }
    
    
}


//MARK: - Collection View

extension RMEpisodeListViewViewModel: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return cellViewModels.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RMEpisodeCollectionViewCell.cellIdentifier, for: indexPath) as? RMEpisodeCollectionViewCell else {
            fatalError("Unsupported cell")
        }
        
        cell.configure(with: cellViewModels[indexPath.row])
        
        return cell
        
    }
    
    // Footer DEQUE - RMFooterLoadingCollectionReusableView
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionFooter,
              let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: RMFooterLoadingCollectionReusableView.identifier,
                for: indexPath) as? RMFooterLoadingCollectionReusableView
        else {
            fatalError("Unsupported")
        }
        
        footer.startAnimating()
        
        return footer
    }
    
    // Footer size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        guard shouldShowMoreIndicator else {
            return .zero
        }
        
        return CGSize(width: collectionView.frame.width, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let bounds = UIScreen.main.bounds
        let width = (bounds.width - 30) / 2
        return CGSize(width: width, height: width * 1.5)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let character = characters[indexPath.row]
        delegate?.didSelectCharacter(character)
    }
    
    
}


//MARK: - ScrollView
extension RMEpisodeListViewViewModel: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard shouldShowMoreIndicator,
              !isLoadingMoreCharacters,
              !cellViewModels.isEmpty,
              let nextUrlString = appInfo?.next,
              let url = URL(string: nextUrlString)
        else {
            return
        }
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] t in
            
            let offset = scrollView.contentOffset.y
            let totalContentHeight = scrollView.contentSize.height
            let totalScrollViewFixedHeight = scrollView.frame.size.height
            
            if offset >= (totalContentHeight - totalScrollViewFixedHeight - 120) {
                self?.fetchAdditionalCharacters(url: url)
            }
            t.invalidate()
        }

    }
    
    
}