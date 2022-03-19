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
    // - MARK: Properties
    
    internal private(set) var data: [Key: Value]
    
    public typealias Element = (key: Key, value: Value)
    
    // - MARK: Initializers
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
    
    // - MARK: Subscripts
    /**
     Accesses the value associated with the given key for reading.
     
     This *key-based* subscript returns the value for the given key if the key
     is found in the dictionary, or `nil` if the key is not found.
     
     The following example creates a new dictionary and prints the value of a
     key found in the dictionary (`"Monday"`) and a key not found in the
     dictionary (`"Sunday"`).
     
            var availableDays = ThreadSafeDictionary(["Monday": 1, "Tuesday": 2, "Wednesday": 3])
            print(await availableDays["Monday"])
            // Prints "Optional(1)"
            print(await availableDays["Sunday"])
            // Prints "nil"
     
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
    
    // - MARK: Methods
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
     
         let data = ThreadSafeDictionary(["a": "1", "b": "three", "c": "///4///"])
         let m: ThreadSafeDictionary<String, Int?> = data.mapValues { str in Int(str) }
         // ["a": Optional(1), "b": nil, "c": nil]
         let c: ThreadSafeDictionary<String, Int?> = data.compactMapValues { str in Int(str) }
         // ["a": 1]
     
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
     
         var dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
         // Keeping existing value for key "a":
         await dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
         // ["b": 2, "a": 1, "c": 4]
         // Taking the new value for key "a":
         await dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
         // ["b": 2, "a": 5, "c": 4, "d": 6]
     
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
     
         var dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
         // Keeping existing value for key "a":
         dictionary.merge(ThreadSafeDictionary(["a": 3, "c": 4])) { (current, _) in current }
         // ["b": 2, "a": 1, "c": 4]
         // Taking the new value for key "a":
         dictionary.merge(ThreadSafeDictionary(["a": 5, "d": 6])) { (_, new) in new }
         // ["b": 2, "a": 5, "c": 4, "d": 6]
     
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
     
         var dictionary = ThreadSafeDictionary(["a": 1, "b": 2])
         // Keeping existing value for key "a":
         dictionary.merge(["a": 3, "c": 4]) { (current, _) in current }
         // ["b": 2, "a": 1, "c": 4]
         // Taking the new value for key "a":
         dictionary.merge(["a": 5, "d": 6]) { (_, new) in new }
         // ["b": 2, "a": 5, "c": 4, "d": 6]
     
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
     Create a copy of the dictionary.
     
     - Returns: A copy of the dictionary.
     */
    public func copy() -> ThreadSafeDictionary<Key, Value> {
        return ThreadSafeDictionary(data)
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
