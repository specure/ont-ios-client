//
//  OrderedDictionary.swift
//  FlickrSearch
//
//  Created by Main Account on 9/14/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

struct OrderedDictionary<KeyType: Hashable, ValueType> {

  typealias ArrayType = [KeyType]
  typealias DictionaryType = [KeyType: ValueType]

  var array = ArrayType()
  var dictionary = DictionaryType()
  var count: Int {
    return self.array.count
  }

  // 1
  mutating func insert(_ value: ValueType, forKey key: KeyType, atIndex index: Int) -> ValueType? {
    var adjustedIndex = index

    // 2
    let existingValue = self.dictionary[key]
    if existingValue != nil {
      // 3
        let existingIndex = self.array.firstIndex(of: key)!

      // 4
      if existingIndex < index {
        adjustedIndex -= 1
      }
      self.array.remove(at: existingIndex)
    }

    // 5
    self.array.insert(key, at: adjustedIndex)
    self.dictionary[key] = value

    // 6
    return existingValue
  }

  // 1
  mutating func removeAtIndex(_ index: Int) -> (KeyType, ValueType) {
    // 2
    precondition(index < self.array.count, "Index out-of-bounds")

    // 3
    let key = self.array.remove(at: index)

    // 4
    let value = self.dictionary.removeValue(forKey: key)!

    // 5
    return (key, value)
  }

  // 1
  subscript(key: KeyType) -> ValueType? {
    // 2(a)
    get {
      // 3
      return self.dictionary[key]
    }
    // 2(b)
    set {
      // 4
        if let _ = self.array.firstIndex(of: key) {
    } else {
        self.array.append(key)
    }

      // 5
      self.dictionary[key] = newValue
    }
  }

  subscript(index: Int) -> (KeyType, ValueType) {
    // 1
    get {
      // 2
      precondition(index < self.array.count, "Index out-of-bounds")
      // 3
      let key = self.array[index]

      // 4
      let value = self.dictionary[key]!

      // 5
      return (key, value)
    }
  }
}
