ROLE_PERMISSIONS = {
    "vlcms_user": {
        "can_view_all": True,
        "can_update_all": True,
        "can_insert_all": True,
        "can_delete_all": True,
        "visible_sections": ["tables", "triggers", "procedures", "functions", "queries"]
    },
    "service_staff": {
        "can_view_all": True,
        "can_update_all": True,
        "can_insert_all": True,
        "can_delete_all": False,
        "visible_sections": ["tables", "triggers", "procedures", "functions", "queries"]
    },
    "service_viewer": {
        "can_view_all": True,
        "can_update_all": False,
        "can_insert_all": False,
        "can_delete_all": False,
        "visible_sections": ["tables", "triggers", "queries"]
    },
    "workshop_owner": {
        "can_view_all": False,                     # not all tables, only specific ones
        "can_update_all": False,
        "can_insert_all": False,
        "can_delete_all": False,
        "can_view": ["workshop", "SERVICE_RECORD"], # specific tables visible for view
        "can_insert": ["workshop"],                 # can insert into workshop
        "can_update": ["workshop"],                 # can update workshop
        "can_delete": [],                           # cannot delete anything
        "visible_sections": ["tables"]              # can only see the tables section
    }
}
