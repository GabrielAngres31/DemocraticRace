local INTERVIEWER_BEHAVIOR = {
    OnInit = function( self, difficulty )
		-- self.bog_boil = self:AddCard("bog_boil")
		self:SetPattern( self.BasicCycle )
        local modifier = self.negotiator:AddModifier("INTERVIEWER")
        -- modifier.agents = shallowcopy(self.agents)
        -- modifier:InitModifiers()
        self.cont_question_card = self:AddCard("contemporary_question_card")
        self.modifier_picker = self:MakePicker()
            :AddArgument("LOADED_QUESTION", 2)
            :AddArgument("PLEASANT_QUESTION", 1)
            :AddCard(self.cont_question_card, 1)
        self.questions_answered = 0 -- jus to make sure
    end,
    available_issues = copyvalues(DemocracyConstants.issue_data),
    params = {},
	BasicCycle = function( self, turns )
		-- Double attack every 2 rounds; Single attack otherwise.
		if self.difficulty >= 4 and turns % 2 == 0 then
			self:ChooseGrowingNumbers( 3, -1 )
		elseif turns % 2 == 0 then
			self:ChooseGrowingNumbers( 2, 0 )
		else
			self:ChooseGrowingNumbers( 1, 1 )
        end
        self.modifier_picker:ChooseCards(turns == 1 and 2 or 1)
	end,
}

local RELATION_OFFSET = {
    [RELATIONSHIP.HATED] = -20,
    [RELATIONSHIP.DISLIKED] = -10,
    [RELATIONSHIP.NEUTRAL] = 0,
    [RELATIONSHIP.LIKED] = 10,
    [RELATIONSHIP.LOVED] = 20,
}


local QDEF = QuestDef.Define
{
    title = "Interview",
    desc = "Do the interview and gain support.",

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater')})
    end,
    -- on_start = function(quest)

    -- end,
}
:AddCast{
    cast_id = "host",
    cast_fn = function(quest, t) 
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
    when = QWHEN.MANUAL,
    events = 
    {
        agent_retired = function( quest, agent )
            -- if quest:IsActive( "get_snail" ) then
                -- If noodle chef died before we even got the snail, cast someone new.
                quest:UnassignCastMember( "host" )
                quest:AssignCastMember( "host" )
            -- end
        end,
    },
}
:AddCastFallback{
    cast_fn = function(quest, t)
        quest:GetCastMember("theater"):GetWorkPosition("host"):TryHire()
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
}
:AddLocationCast{
    cast_id = "theater",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER"))
    end,
    on_assign = function(quest, location)
        quest:SpawnTempLocation("BACKROOM", "backroom")
        quest:AssignCastMember("host")
    end,
    no_validation = true,
}
:AddLocationCast{
    cast_id = "backroom",
    no_validation = true,
    on_assign = function(quest, location)
        location:SetMapPos( quest:GetCastMember("theater"):GetMapPos() )
    end,
    when = QWHEN.MANUAL,
}
:AddObjective{
    id = "go_to_interview",
    title = "Go to interview",
    desc = "Meet up with {primary_advisor} at the Grand Theater.",
    mark = {"backroom"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "do_interview",
    title = "Do the interview",
    desc = "Try not to embarrass yourself.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
}

:AddLocationDefs{
    BACKROOM = {
        name = "Grand Theater Back Room",
        plax = "INT_Auction_Backroom_1",
        map_tags = {"city"},
        indoors = true,
    },
}

:AddOpinionEvents{
    likes_interview = {
        delta = OPINION_DELTAS.OPINION_UP,
        txt = "Likes your interview",
    },
    dislikes_interview = {
        delta = OPINION_DELTAS.TO_HATED,
        txt = "Dislikes your interview",
    }
}

DemocracyUtil.AddPrimaryAdvisor(QDEF, true)

QDEF:AddConvo("go_to_interview")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("backroom") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrive at the Grand Theater, and you see that {primary_advisor} is waiting for you.
                player:
                    !left
                primary_advisor:
                    !right
                    are you ready?
                player:
                    aye aye, captain.
                primary_advisor:
                    i can't heeeear you!
                player:
                    AYE AYE CAPTAIN!
                primary_advisor:
                    oooooo!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_interview")
            cxt.quest:Activate("do_interview")
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Fn(function(cxt)
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("theater"))
                end)
                :MakeUnder()
        end)
QDEF:AddConvo("do_interview")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("theater") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] when you enter the room, you see a bunch of people
                * Looks liek lots of people wants to watch your interview.
                agent:
                    !right
                    let's welcome our special guest tonight, {player}!
                player:
                    !left
                * everyone clapped.
                * try to survive the interview, i guess?
            ]],
            OPT_DO_INTERVIEW = "Do the interview",
            DIALOG_INTERVIEW_SUCCESS = [[
                agent:
                    [p] once again, thank you for coming.
                player:
                    no problems.
                * phew! you survived the interview.
            ]],
            DIALOG_INTERVIEW_FAIL = [[
                player:
                    [p] i said something embarrassing and outrageous in front of everyone!
                * awkward silence.
                * oh no.
                * this embarrassment is so huge you lost the game!
            ]],
            DIALOG_INTERVIEW_AFTER = [[
                * After the interview, {1*a person confronts you|several people confront you}.
            ]],
            OPT_ACCEPT_LOSS = "Accept your failure",
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("host"))
            cxt:Dialog("DIALOG_INTRO")
            cxt:GetAgent().temp_negotiation_behaviour = INTERVIEWER_BEHAVIOR
            local agent_supports = {}
            for i, agent in cxt.quest:GetCastMember("theater"):Agents() do
                if agent:GetBrain():IsPatronizing() then
                    table.insert(agent_supports, {agent, DemocracyUtil.TryMainQuestFn("GetSupportForAgent", agent)})
                end
            end
            cxt:Opt("OPT_DO_INTERVIEW")
                :Negotiation{
                    on_success = function(cxt, minigame)
                        cxt:Dialog("DIALOG_INTERVIEW_SUCCESS")
                        TheGame:GetDebug():CreatePanel(DebugTable(INTERVIEWER_BEHAVIOR))
                        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", (INTERVIEWER_BEHAVIOR.params.questions_answered or 0) * 2)
                        -- Big calculations that happens.
                        local agent_response = {}
                        for i, data in ipairs(agent_supports) do
                            local current_support = DemocracyUtil.TryMainQuestFn("GetSupportForAgent", data[1])
                            local support_delta = current_support - data[2] + RELATION_OFFSET[data[1]:GetRelationship()] + math.random(-30, 30)
                            if support_delta > 25 then
                                table.insert(agent_response, {data[1], "likes_interview"})
                            elseif support_delta < -25 then
                                table.insert(agent_response, {data[1], "dislikes_interview"})
                            end
                        end
                        if #agent_response > 0 then
                            cxt:Dialog("DIALOG_INTERVIEW_AFTER", #agent_response)
                            for i, data in ipairs(agent_response) do
                                cxt.enc:PresentAgent(data[1], SIDE.RIGHT)
                                cxt:Quip(data[1], "post_interview", data[2])
                                data[1]:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent(data[2]))
                            end
                        end

                        cxt:Opt("OPT_DONE")
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_INTERVIEW_FAIL")
                        cxt:Opt("OPT_ACCEPT_LOSS")
                            :Fn(function(cxt)
                                TheGame:Lose()
                            end)
                    end,
                }
        end)