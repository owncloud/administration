Feature: Parsing
  Scenario: Parse simple query log
    When parsing the file "data/1-simple.log"
    Then the result should be
      | type | table | count |
      | SELECT | oc_preferences | 1 |
      | UPDATE | oc_preferences | 1 |
      | INSERT | oc_filecache | 1 |
      | SELECT-JOIN | oc_share | 1 |
      | DELETE | oc_file_locks | 1 |

  Scenario: Parse simple query log with line break
    When parsing the file "data/2-line-break.log"
    Then the result should be
      | type | table | count |
      | SELECT | oc_filecache | 1 |

  Scenario: Parse query log and combine similar queries
    When parsing the file "data/3-group.log"
    Then the result should be
      | type | table | count |
      | SELECT | oc_preferences | 5 |
      | SELECT | oc_appconfig | 1 |

