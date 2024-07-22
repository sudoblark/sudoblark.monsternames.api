Feature: API functionality
  Scenario Outline: /goatmen
    Given payload fields <fields>
    And payload values <values>
    Then I should be able to POST
    And GET will contain all fields

    Examples:
    | fields | values |
    | first_name | Fluffy |
    | first_name | Squiggles |
    | first_name | Flopsy |
    | first_name | Bugsy  |
    | first_name | Tooty |


  Scenario Outline: /goblin
    Given payload fields <fields>
    And payload values <values>
    Then I should be able to POST
    And GET will contain all fields

    Examples:
    | fields | values |
    | first_name,last_name | Barry,Clark |
    | first_name,last_name | Steve,Smith |
    | first_name,last_name | Dave,Taylor |
    | first_name,last_name | John,Brown  |
    | first_name,last_name | Lemons,Ball |

  Scenario Outline: /ogre
    Given payload fields <fields>
    And payload values <values>
    Then I should be able to POST
    And GET will contain all fields

    Examples:
    | fields | values |
    | first_name | Thudd |
    | first_name | Mud |
    | first_name | Uh |
    | first_name | Ug  |
    | first_name | Bluh |

  Scenario Outline: /orc
    Given payload fields <fields>
    And payload values <values>
    Then I should be able to POST
    And GET will contain all fields

    Examples:
    | fields | values |
    | first_name,last_name | Table,The Weak |
    | first_name,last_name | Chair,The Toothless |
    | first_name,last_name | Roof,The Sizzler |
    | first_name,last_name | Dinner,The Sandwich  |
    | first_name,last_name | Bin,The Nugget |

  Scenario Outline: /skeleton
    Given payload fields <fields>
    And payload values <values>
    Then I should be able to POST
    And GET will contain all fields

    Examples:
    | fields | values |
    | first_name,last_name | Cecil,Of Sussex |
    | first_name,last_name | Hugo,Belvoir |
    | first_name,last_name | Sir Lucis,Glaviston |
    | first_name,last_name | Lord,Tudor  |
    | first_name,last_name | Lady,Windsor |

  Scenario Outline: /troll
    Given payload fields <fields>
    And payload values <values>
    Then I should be able to POST
    And GET will contain all fields

    Examples:
    | fields | values |
    | first_name,last_name | Ivar,Ivar |
    | first_name,last_name | Flug,Flug |
    | first_name,last_name | Orb,Orb |
    | first_name,last_name | Jung,Jung  |
    | first_name,last_name | Ulfric,Ulric |