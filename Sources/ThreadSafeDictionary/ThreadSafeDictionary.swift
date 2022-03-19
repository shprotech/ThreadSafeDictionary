//
//  ThreadSafeDictionary.swift
//  TransMusic
//
//  Created by Shahar Melamed on 19/03/2022.
//

import Foundation

/// A thread-safe implementation of a dictionary.
/// - Note: The dict is a refrence type.
public actor ThreadSafeDictionary<Key: Hashable, Value> {
    // MARK: - Properties
    
    internal private(set) var data: [Key: Value]
    
    public typealias Element = (key: Key, value: Value)
    
    // MARK: - Initializers
    /// Initialize with an empty dict.
    public init() {
        data = [:]
    }
    
    /**
     Initialize with a predefined dict.
     - Parameter content: The content to initialize the dict to.
     */
    public init(_ content: [Key: Value]) {
        data = content
    }
    
    // MARK: - Subscripts
    /**
     Accesses the value associated with the given key for reading.
     
     This *key-based* subscript returns the value for the given key if the key
     is found in the dictionary, or `nil` if the key is not found.
     
     The following example creates a new dictionary and prints the value of a
     key found in the dictionary (`"Monday"`) and a key not found in the
     dictionary (`"Sunday"`).
     
     ```swift
    var availableDays = ThreadSafeDictionary(["Monday": 1, "Tuesday": 2, "Wednesday": 3])
    print(await availableDays["Monday"])
    // Prints "Optional(1)"
    print(await availableDays["Sunday"])
    // Prints "nil"
     ```
     
     - Parameter key: The key to find in the dictionary.
     - Returns: The value associated with  `key` if `key` is in the dictionary;
     otherwise, `nil`.
     */
    public subscript(index: Key) -> Value? {
        return get(index)
    }
    
    /**
     Accesses the value with the given key, falling back to the given default
     value if the key isn't found.
     
     - Parameters:
       - Key: The key to look up in the dictionary.
       - defaultValue: The default value to use if `key` doesn't exists in the
         dictionary.
     - Returns: The value associated with `key` in the dictionary; otherwise,
       `defaultValue`.
     */
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        data[key, default: defaultValue()]
    }
    
    // MARK: - Methods
    /**
     Get a value from the dict.
     - Parameter key: The key of the cache to read.
     - Returns: The stored value if exists, otherwise returns nil.
     */
    public func get(_ key: Key) -> Value? {
        return data[key]
    }
    
    /**
     Set a new value to the given key (even if already exists).
     
     - Parameter key: The key to store the value in.
     - Parameter value: The new value.
     - Note: Pass nil to remove the value.
     - Returns: The value that was replaced, or `nil` if a new key-value pair was added.
     */
    public func set(_ key: Key, to value: Value?) -> Value? {
        var oldValue: Value? = nil
        if data.keys.contains(key) {
            oldValue = data[key]
        }
        
        data[key] = value
        return oldValue
    }
    
    /**
     Returns a new ThreadSafeDictionary containing the key-value pairs of the
     dictionary that satisfy the given predicate.
     
     - Parameter isIncluded: A closure that takes a key-value pair as its
     argument and returns a Boolean value indicating whether the pair
     should be included in the returned dictionary.
     - Returns: A ThreadSafeDictionary of the key-value pairs that `isIncluded` allows.
     */
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> ThreadSafeDictionary<Key, Value> {
        ThreadSafeDictionary(try data.filter(isIncluded))
    }
    
    /**
     Returns a new ThreadSafeDictionary containing the keys of this dictionary with the
     values transformed by the given closure.
 
     - Parameter transform: A closure that transforms a value. `transform`
     accepts each value of the dictionary as its parameter and returns a
     transformed value of the same or of a different type.
     - Returns: A dictionary containing the keys and transformed values of
     this dictionary.
 
     - Complexity: O(*n*), where *n* is the length of the dictionary.
     */
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> ThreadSafeDictionary<Key, T> {
        ThreadSafeDictionary<Key, T>(try data.mapValues(transform))
    }
    
    /**
     Returns a new ThreadSafeDictionary containing only the key-value pairs that have
     non-`nil` values as the result of transformation by the given closure.
     
     Use this method to receive a dictionary with non-optional values when
     your transformation produces optional values.
     
     In this example, note the difference in the result of using `mapValues`
     and `compactMapValues` with a transformation that returns an optional
     `Int` value.
    
     ```swift
     let data = ThreadSafeDictionary(["a": "1", "b": "three", "c": "///4///"])
     let m: ThreadSafeDictionary<String, Int?> = data.mapValues { str in Int(str) }
     // ["a": Optional(1), "b": nil, "c": nil]
     let c: ThreadSafeDictionary<String, Int?> = data.compactMapValues { str in Int(str) }
     // ["a": 1]
     ```
     
     - Parameter transform: A closure that transforms a value. `transform`
       accepts each value of the dictionary as its parameter and returns an
       optional transformed value of the same or of a different type.
     - Returns: A dictionary containing the keys and non-`nil` transformed
       values of this dictionary.
     - Complexity: O(*m* + *n*), where *n* is the length of the original
       dictionary and *m* is the length of the resulting dictionary.
     */
    public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> ThreadSafeDictionary<Key, T> {
        ThreadSafeDictionary<Key, T>(try data.compactMapValues(transform))
    }
    
    /**
     Merges the key-value pairs in the given sequence into the dictionary,
     using a combining closure to determine the value for any duplicate keys.
     
     Use the `combine` closure to select a value to use in the updated
     dictionary, or to combine existing and new values. As the key-value
     pairs are merged with the dictionary, the `combine` closure is called
     with the current and new values for any duplicate keys that are
     encountered.
     
     This example shows how to choose the current or new values for any
     duplicate keys:
     
     ```swift
     var dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
     // Keeping existing value for key "a":
     await dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
     // ["b": 2, "a": 1, "c": 4]
     // Taking the new value for key "a":
     await dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
     // ["b": 2, "a": 5, "c": 4, "d": 6]
     ```
     
     - Parameters:
       - other:  A sequence of key-value pairs.
       - combine: A closure that takes the current and new values for any
         duplicate keys. The closure returns the desired value for the final
         dictionary.
     */
    public func merge<S: Sequence>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S.Element == (Key, Value) {
        try data.merge(other, uniquingKeysWith: combine)
    }
    
    /**
     Merges the given dictionary into this dictionary, using a combining
     closure to determine the value for any duplicate keys.
     
     Use the `combine` closure to select a value to use in the updated
     dictionary, or to combine existing and new values. As the key-values
     pairs in `other` are merged with this dictionary, the `combine` closure
     is called with the current and new values for any duplicate keys that
     are encountered.
     
     This example shows how to choose the current or new values for any
     duplicate keys:
     
     ```swift
     var dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
     // Keeping existing value for key "a":
     await dictionary.merge(ThreadSafeDictionary(["a": 3, "c": 4])) { (current, _) in current }
     // ["b": 2, "a": 1, "c": 4]
     // Taking the new value for key "a":
     await dictionary.merge(ThreadSafeDictionary(["a": 5, "d": 6])) { (_, new) in new }
     // ["b": 2, "a": 5, "c": 4, "d": 6]
     ```
     
     - Parameters:
       - other:  A dictionary to merge.
       - combine: A closure that takes the current and new values for any
         duplicate keys. The closure returns the desired value for the final
         dictionary.
     */
    public func merge(_ other: ThreadSafeDictionary<Key, Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) async rethrows {
        try data.merge(await other.data, uniquingKeysWith: combine)
    }
    
    /**
     Merges the given dictionary into this dictionary, using a combining
     closure to determine the value for any duplicate keys.
     
     Use the `combine` closure to select a value to use in the updated
     dictionary, or to combine existing and new values. As the key-values
     pairs in `other` are merged with this dictionary, the `combine` closure
     is called with the current and new values for any duplicate keys that
     are encountered.
     
     This example shows how to choose the current or new values for any
     duplicate keys:
     
     ```swift
     var dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
     // Keeping existing value for key "a":
     await dictionary.merge(["a": 3, "c": 4]) { (current, _) in current }
     // ["b": 2, "a": 1, "c": 4]
     // Taking the new value for key "a":
     await dictionary.merge(["a": 5, "d": 6]) { (_, new) in new }
     // ["b": 2, "a": 5, "c": 4, "d": 6]
     ```
     
     - Parameters:
       - other:  A dictionary to merge.
       - combine: A closure that takes the current and new values for any
         duplicate keys. The closure returns the desired value for the final
         dictionary.
     */
    public func merge(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows {
        try data.merge(other, uniquingKeysWith: combine)
    }
    
    /**
     Creates a dictionary by merging key-value pairs in a sequence into the
     dictionary, using a combining closure to determine the value for
     duplicate keys.
     
     Use the `combine` closure to select a value to use in the returned
     dictionary, or to combine existing and new values. As the key-value
     pairs are merged with the dictionary, the `combine` closure is called
     with the current and new values for any duplicate keys that are
     encountered.
     
     This example shows how to choose the current or new values for any
     duplicate keys:
     
     ```swift
     let dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
     let newKeyValues = zip(["a", "b"], [3, 4])
     let keepingCurrent = await dictionary.merging(newKeyValues) { (current, _) in current }
     // ["b": 2, "a": 1]
     let replacingCurrent = await dictionary.merging(newKeyValues) { (_, new) in new }
     // ["b": 4, "a": 3]
     ```
     
     - Parameters:
       - other:  A sequence of key-value pairs.
       - combine: A closure that takes the current and new values for any
         duplicate keys. The closure returns the desired value for the final
         dictionary.
     - Returns: A new dictionary with the combined keys and values of this
       dictionary and `other`.
     */
    public func merging<S: Sequence>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> ThreadSafeDictionary<Key, Value> where S.Element == (Key, Value) {
        ThreadSafeDictionary(try data.merging(other, uniquingKeysWith: combine))
    }
    
    /**
     Creates a dictionary by merging the given dictionary into this
     dictionary, using a combining closure to determine the value for
     duplicate keys.
     
     Use the `combine` closure to select a value to use in the returned
     dictionary, or to combine existing and new values. As the key-value
     pairs in `other` are merged with this dictionary, the `combine` closure
     is called with the current and new values for any duplicate keys that
     are encountered.
     
     This example shows how to choose the current or new values for any
     duplicate keys:
     
     ```swift
     let dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
     let otherDictionary = ThreadSafeDictionary(["a": 3, "b": 4])
     let keepingCurrent = await dictionary.merging(otherDictionary)
           { (current, _) in current }
     // ["b": 2, "a": 1]
     let replacingCurrent = await dictionary.merging(otherDictionary)
           { (_, new) in new }
     // ["b": 4, "a": 3]
     ```
     
     - Parameters:
       - other:  A dictionary to merge.
       - combine: A closure that takes the current and new values for any
         duplicate keys. The closure returns the desired value for the final
         dictionary.
     - Returns: A new dictionary with the combined keys and values of this
       dictionary and `other`.
     */
    public func merging(_ other: ThreadSafeDictionary<Key, Value>, uniquingKeysWith combine: (Value, Value) throws -> Value) async rethrows -> ThreadSafeDictionary<Key, Value> {
        ThreadSafeDictionary(try data.merging(await other.data, uniquingKeysWith: combine))
    }
    
    /**
     Creates a dictionary by merging the given dictionary into this
     dictionary, using a combining closure to determine the value for
     duplicate keys.
     
     Use the `combine` closure to select a value to use in the returned
     dictionary, or to combine existing and new values. As the key-value
     pairs in `other` are merged with this dictionary, the `combine` closure
     is called with the current and new values for any duplicate keys that
     are encountered.
     
     This example shows how to choose the current or new values for any
     duplicate keys:
     
     ```swift
     let dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
     let otherDictionary = ["a": 3, "b": 4]
     let keepingCurrent = await dictionary.merging(otherDictionary)
           { (current, _) in current }
     // ["b": 2, "a": 1]
     let replacingCurrent = await dictionary.merging(otherDictionary)
           { (_, new) in new }
     // ["b": 4, "a": 3]
     ```
     
     - Parameters:
       - other:  A dictionary to merge.
       - combine: A closure that takes the current and new values for any
         duplicate keys. The closure returns the desired value for the final
         dictionary.
     - Returns: A new dictionary with the combined keys and values of this
       dictionary and `other`.
     */
    public func merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) async rethrows -> ThreadSafeDictionary<Key, Value> {
        ThreadSafeDictionary(try data.merging(other, uniquingKeysWith: combine))
    }
    
    /**
     Removes the given key and its associated value from the dictionary.
     
     If the key is found in the dictionary, this method returns the key's
     associated value. On removal, this method invalidates all indices with
     respect to the dictionary.
     
     ```swift
     var hues = ThreadSafeDictionary(["Heliotrope": 296, "Coral": 16, "Aquamarine": 156])
     if let value = await hues.removeValue(forKey: "Coral") {
         print("The value \(value) was removed.")
     }
     // Prints "The value 16 was removed."
     ```
     
     If the key isn't found in the dictionary, `removeValue(forKey:)` returns
     `nil`.
     
     ```swift
     if let value = await hues.removeValue(forKey: "Cerise") {
         print("The value \(value) was removed.")
     } else {
         print("No value found for that key.")
     }
     // Prints "No value found for that key."
     ```
     
     - Parameter key: The key to remove along with its associated value.
     - Returns: The value that was removed, or `nil` if the key was not
       present in the dictionary.
     
     - Complexity: O(*n*), where *n* is the number of key-value pairs in the
       dictionary.
     */
    public func removeValue(forKey key: Key) -> Value? {
        data.removeValue(forKey: key)
    }
    
    /**
     Removes all key-value pairs from the dictionary.
     
     Calling this method invalidates all indices with respect to the
     dictionary.
     
     - Parameter keepCapacity: Whether the dictionary should keep its
       underlying buffer. If you pass `true`, the operation preserves the
       buffer capacity that the collection has, otherwise the underlying
       buffer is released.  The default is `false`.
     
     - Complexity: O(*n*), where *n* is the number of key-value pairs in the
       dictionary.
     */
    public func removeAll(keepingCapacity keepCapacity: Bool = false) {
        data.removeAll(keepingCapacity: keepCapacity)
    }
    
    /**
     Removes and returns the first key-value pair of the dictionary if the
     dictionary isn't empty.
     
     The first element of the dictionary is not necessarily the first element
     added. Don't expect any particular ordering of key-value pairs.
     
     - Returns: The first key-value pair of the dictionary if the dictionary
       is not empty; otherwise, `nil`.
     - Complexity: Averages to O(1) over many calls to `popFirst()`.
     */
    public func popFirst() -> Element? {
        data.popFirst()
    }
    
    /**
     Returns an array containing the results of mapping the given closure
     over the sequence's elements.
     
     In this example, `map` is used first to convert the names in the array
     to lowercase strings and then to count their characters.
     
     ```swift
     let cast = ["Vivien", "Marlon", "Kim", "Karl"]
     let lowercaseNames = cast.map { $0.lowercased() }
     // 'lowercaseNames' == ["vivien", "marlon", "kim", "karl"]
     let letterCounts = cast.map { $0.count }
     // 'letterCounts' == [6, 6, 3, 4]
     ```
     
     - Parameter transform: A mapping closure. `transform` accepts an
       element of this sequence as its parameter and returns a transformed
       value of the same or of a different type.
     - Returns: An array containing the transformed elements of this
       sequence.
     */
    public func map<T>(_ transform: ((key: Key, value: Value)) throws -> T) rethrows -> [T] {
        try data.map(transform)
    }
    
    /**
     Returns a subsequence containing all but the given number of initial
     elements.
     If the number of elements to drop exceeds the number of elements in
     the collection, the result is an empty subsequence.
         let numbers = [1, 2, 3, 4, 5]
         print(numbers.dropFirst(2))
         // Prints "[3, 4, 5]"
         print(numbers.dropFirst(10))
         // Prints "[]"
     - Parameter k: The number of elements to drop from the beginning of
       the collection. `k` must be greater than or equal to zero.
     - Returns: A subsequence starting after the specified number of
       elements.
     - Complexity: O(1) if the collection conforms to
       `RandomAccessCollection`; otherwise, O(*k*), where *k* is the number of
       elements to drop from the beginning of the collection.
     */
    public func dropFirst(_ k: Int = 1) -> Slice<Dictionary<Key, Value>> {
        data.dropFirst(k)
    }
    
    /**
     Create a copy of the dictionary.
     
     - Returns: A copy of the dictionary.
     */
    public func copy() -> ThreadSafeDictionary<Key, Value> {
        return ThreadSafeDictionary(data)
    }
    
    /**
     Get a copy of the dictionary as a regular `Dictionary` instance.
     
     - Returns: The dictionary as a regular `Dictionary` instance.
     */
    public func unsafeDictionary() -> [Key: Value] {
        data
    }
}

extension ThreadSafeDictionary where Value: Equatable {
    /**
     Use this method to check if the current dictionary and other dictionary are equal.
     
     - Returns: If the two dictionaries are equal.
     */
    func isEqual(_ other: ThreadSafeDictionary<Key, Value>) async -> Bool {
        return await data == other.data
    }
}
