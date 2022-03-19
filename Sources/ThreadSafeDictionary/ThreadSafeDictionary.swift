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
    internal private(set) var data: [Key: Value]
    
    public typealias Element = (key: Key, value: Value)
    
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
     */
    public func set(_ key: Key, to value: Value?) {
        guard let value = value else {
            data.removeValue(forKey: key)
            return
        }
        
        data[key] = value
    }
    
    public subscript(index: Key) -> Value? {
        return get(index)
    }
    
    /// Initialize to an empty dict.
    public init() {
        data = [:]
    }
    
    /**
     Initialize to a predefined dict.
     - Parameter content: The content to initialize the dict to.
     */
    public init(_ content: [Key: Value]) {
        data = content
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
     
         let data = ["a": "1", "b": "three", "c": "///4///"]
         let m: [String: Int?] = data.mapValues { str in Int(str) }
         // ["a": Optional(1), "b": nil, "c": nil]
         let c: [String: Int] = data.compactMapValues { str in Int(str) }
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
     Create a copy of the dictionary.
     
     - Returns: A copy of the dictionary.
     */
    public func copy() -> ThreadSafeDictionary<Key, Value> {
        return ThreadSafeDictionary(data)
    }
}
