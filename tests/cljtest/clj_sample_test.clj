(ns clj-sample-test
  (:require [clojure.test :refer [deftest testing is]]))

(deftest sample-test
  (testing "we can run and see feedback for successful tests in replica.nvim"
    (is false)))
