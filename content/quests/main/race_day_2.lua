local QDEF = QuestDef.Define
{
    title = "Campaign Time",
    desc = "Continue to campaign and gain support among the people.",

    qtype = QTYPE.STORY,

    on_start = function(quest)
        quest:Activate("starting_out")
        TheGame:GetGameState():GetPlayerAgent():MoveToLocation( quest:GetCastMember("home") )
    end,
}
:Loc{
    GET_JOB_ALONE = "Think of a way to gain support.",
    GET_JOB_ADVISOR = "Discuss with {primary_advisor} about how to gain support.",
}
:AddSubQuest{
    id = "meet_opposition",
    quest_id = "RACE_INTRODUCE_OPPOSITION",
    on_complete = function(quest)
        quest:Activate("get_job")
    end,
}
:AddObjective{
    id = "starting_out",
    title = "Talk to {primary_advisor} about the plan.",
    on_complete = function(quest)
        quest:Activate("get_job")
    end,
}
:AddObjective{
    id = "get_job",
    title = "Find on a way to gain support",
    mark = {"primary_advisor"},
    desc = "",
    desc_fn = function(quest, str)
        return quest:GetCastMember("primary_advisor")
            and quest:GetLocalizedStr( "GET_JOB_ADVISOR" )
            or quest:GetLocalizedStr( "GET_JOB_ALONE" )
    end,
    
    on_complete = function(quest) 
        quest:Activate("do_job")
    end,
    
}
:AddObjective{
    id = "do_job",
    hide_in_overlay = true,
    events = 
    {
        quests_changed = function(quest, event_quest)
            if quest.param.current_job == event_quest and not event_quest:IsActive() then
                quest:Complete("do_job")
            end
        end
    },

    on_complete = function(quest) 
        quest.param.job_history = quest.param.job_history or {}
        table.insert(quest.param.job_history, quest.param.current_job)
        quest.param.recent_job = quest.param.current_job
        quest.param.current_job = nil

        if (#quest.param.job_history == 1) then 
            quest:Activate("meet_opposition")
        -- elseif (#quest.param.job_history >= 2) then
        --     quest:Activate("do_summary")
        else
            quest:Activate("get_job")
            DemocracyUtil.StartFreeTime()
        end
    end,

}
DemocracyUtil.AddOptionalPrimaryAdvisor(QDEF)
DemocracyUtil.AddHomeCasts(QDEF)

QDEF:AddConvo("starting_out", "primary_advisor")
    :ConfrontState("STATE_CONFRONT")
    :Loc{
        DIALOG_INTRO = [[
            * [p] you wake up to see {primary_advisor}.
            primary_advisor:
                Yo.
                Do work.
            player:
                ok.
            primary_advisor:
                oh, people also hate you for no reason.
            player:
                ok.
            primary_advisor:
                tonight is very important for you campaign.
                you will have a interview.
                if you do well on it, it will surely boost your popularity.
        ]]
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        TheGame:GetGameState():GetMainQuest():DefFn("DoRandomOpposition", 3)
        cxt.quest:Complete("starting_out")
    end)

QDEF:AddConvo("get_job")
    :ConfrontState("STATE_CONFRONT", function(cxt)
        if not cxt.quest:GetCastMember("primary_advisor") then
            cxt.quest:AssignCastMember("primary_advisor")
        end
        return not (cxt.quest:GetCastMember("primary_advisor") and true or false)
    end)
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                !thought
                $neutralThoughtful
                Here's what I can do...
            ]],
        
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        TheGame:GetGameState():GetMainQuest():DefFn("OfferJobs", cxt, 2, "RALLY_JOB")
    end)
QDEF:AddConvo("get_job", "primary_advisor")
    :Loc{
        OPT_GET_JOB = "Discuss Job...",
        DIALOG_GET_JOB = [[
            agent:
                !thought
                $neutralThoughtful
                Here's what we can do...
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_GET_JOB")
            :SetQuestMark( cxt.quest )
            :Dialog("DIALOG_GET_JOB")
            :Fn(function(cxt)
                TheGame:GetGameState():GetMainQuest():DefFn("OfferJobs", cxt, 2, "RALLY_JOB")
            end)
    end)