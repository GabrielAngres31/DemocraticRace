local function CanFeed(agent, quest)
    return DemocracyUtil.RandomBystanderCondition(agent)
        and not (quest.param.gifted_people and table.arraycontains(quest.param.gifted_people, agent))
        and not (quest.param.rejected_people and table.arraycontains(quest.param.rejected_people, agent))
end

local QDEF = QuestDef.Define{
    title = "Dole out",
    desc = "Give Bread to the poor to gain support",
    qtype = QTYPE.SIDE,
    rank = {2, 5},
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,

    on_start = function(quest)
        quest:Activate("dole_out_three")
        quest:Activate("time_countdown")
    end,

    on_complete = function(quest)
        -- if quest.param.poor_performance then
        --     DemocracyUtil.DeltaGeneralSupport(2 * #quest.param.posted_location, "POOR_QUEST")
        -- else
        local score = 3 * (quest.param.gifted_people and #quest.param.gifted_people or 0)
        DemocracyUtil.DeltaGeneralSupport(score, "COMPLETED_QUEST")
        -- end
    end,

    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    end,
}
:AddObjective{
    id = "go_to_advisor",
    title = "Wait for the votes to roll in",
    desc = "You've given your last bit of bread. Report back to {primary_advisor} for a reward.",
    mark = {"primary_advisor"},

    on_activate = function(quest)

    end,
}
:AddObjective{
    id = "dole_out_three",
    title = "Feed some people",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for i, agent in location:Agents() do
                if CanFeed(agent, quest) then
                    table.insert(t, agent)
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t)
        end
    end,
}
:AddFreeTimeObjective{
    desc = "Use this time to find people to feed with your dole loaves",
    action_multiplier = 1.5,
    on_complete = function(quest)
        if quest:IsActive("dole_out_three") then
            quest:Complete("dole_out_three")
        end
        quest:Activate("go_to_advisor")
    end,
}
-- :AddObjective{
--     id = "feed_people",
--     title = "Find and Feed some people",
--     desc = "Go around and find some impoverished to feed.",
-- }
-- :AddObjective{
--     id = "feed_grateful",
--     mark = { "grateful" },
--     title = "Feed some people",
--     desc = "Find someone and give them some bread",
-- }
-- :AddObjective{
--     id = "feed_pan",
--     --mark = { "pan" },
--     title = "Feed some people",
--     desc = "Find someone and give them some bread",
-- }
-- :AddObjective{
--     id = "feed_politic",
--     mark = { "political" },
--     title = "Feed some people",
--     desc = "Find someone and give them some bread",
-- }
-- :AddObjective{
--     id = "feed_ungrate",
--     mark = { "ungrateful" },
--     title = "Feed some people",
--     desc = "Find someone and give them some bread",
-- }
:AddOpinionEvents{
    politic = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Changed political opinion for them.",
    },
    paid = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Gave them money and bread.",
    },
    peeved = {
        delta = OPINION_DELTAS.BAD,
        txt = "Called a populist.",
    },
    political_waffle = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Agreed with them on all the big issues.",
    },
    political_angry = {
        delta = OPINION_DELTAS.BAD,
        txt = "Let them call you a strawman.",
    },
}
-- Added true to make primary advisor mandatory.
-- Otherwise the game will softlock.
-- Fair enough.
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            {has_primary_advisor?
                *{primary_advisor} heaves a large bag onto the table.
                agent:
                    This. Is a bag.
                player:
                    Dear hesh.
                agent:
                    There's more.
                player:
                    No...
                agent:
                    It's filled with dole loaves. Despite them being the poor man's food, I had to sneak some out of the distribution offices.
                player:
                    So why'd you bring it? I'd assume we're not eating any of it.
                agent:
                    No we're not. You're going to distribute these loaves of bread around the Foam.
                    With any luck, the word'll be spread that you're a benevolent politician.
            }
            {not has_primary_advisor?
                player:
                    [p] I say thing.
            }
        ]],
    }
    :State("START")
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
    end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.ACCEPTED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                Well you make a sound case.
                If nothing else we can eat 'em later
                * You pick up the bag. The smell alone rushes you to the door.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
           cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                Won't this make me seem a communist?
            agent:
                Half the workers are in support of communism. This'd be a slam dunk for PR.
            player:
                Lets just keep our options open. What else do you have?
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("dole_out_three")
    :Loc{
        DIALOG_SATISFIES_CONDITIONS = [[
            agent:
                What do you want? why do you have bread?
        ]],
        OPT_GIVE_BREAD = "[p] give bread",
    }
        --this is the randomizer. for some reason the option part doesn't work for some reason, but i'll fix that at some point
    :Hub(function(cxt, who)
        if who and CanFeed(who, cxt.quest) then
            cxt.quest.param.gifted_people = cxt.quest.param.gifted_people or {}
            cxt.quest.param.rejected_people = cxt.quest.param.rejected_people or {}
            cxt:Opt("OPT_GIVE_BREAD")
                :Dialog("DIALOG_SATISFIES_CONDITIONS")
                :SetQuestMark()
                :RequireFreeTimeAction(1)
                :Fn(function(cxt)
                    local weight = {
                        STATE_PANHANDLER = 1,
                        STATE_GRATEFUL = 3,
                        STATE_UNGRATEFUL = who:GetRenown() * who:GetRenown(),
                        STATE_POLITICAL = 1,
                    }
                    if who:GetFactionID() == "RISE" then
                        weight.STATE_POLITICAL = weight.STATE_POLITICAL + 1
                    end
                    local state = weightedpick(weight)
                    cxt:GoTo(state)
                end)
        end
    end)
    :State("STATE_PANHANDLER")
        :Loc{
            DIALOG_PAN_HANDLE = [[
                * [p] You find {agent} sitting on the side of the road, sullen.
                player:
                    Hey there friend. You want a loaf of Dole Bread?
                agent:
                    I wouldn't say no to free bread.
                    although...this isn't really covering rent.
                player:
                    What do you mean? Do you need money?
                agent:
                    Well, yes. I wouldn't force you to not give me money.
                    But i'm also not NOT forcing you to give me money.
            ]],
            OPT_GIVE = "Give them some Shills",
            DIALOG_GIVE = [[
                player:
                    Well, I suppose I'll have a lot more money when i'm in office.
                    Here's a bit of cash. Hope it sees you through to tommorrow.
                agent:
                    Wow. I'll be honest, I did not expect that to work.
                    Thank you so much!
            ]],
            OPT_NO_MONEY = "Give them the bread...then a wide berth",
            DIALOG_NO_MONEY = [[
            player:
                My sympathies, but I am not the most flush as well.
                When i get into office, I will make sure this kind of thing doesn't happen again.
            agent:
                sure...
            ]],
        }
        :Fn(function(cxt)
            --these bricks of code here and the other parts are not needed. the main function/thing/rig-a-ma-jig does this work for it without multiple cast roles on one character
            --if who and not AgentUtil.HasPlotArmour(who) and (who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() >= 2) or (who:GetFactionID() == "RISE" and who:GetRenown() >= 2)
                --and not (who:GetProprietor()) then
            --cxt:Opt("OPT_GIVE_BREAD")
            --cxt.quest:AssignCastMember("pan", cxt:GetAgent())
            cxt:Dialog("DIALOG_PAN_HANDLE")
            table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
            cxt:Opt("OPT_GIVE")
                :Dialog("DIALOG_GIVE")
                :DeliverMoney(100)
                :ReceiveOpinion("paid")
                :DoneConvo()
                    -- :CompleteQuest("feed_pan")
            cxt:Opt("OPT_NO_MONEY")
                :Dialog("DIALOG_NO_MONEY")
                :DoneConvo()
                -- :CompleteQuest("feed_pan")
        end)
    --I have probably gotten needlessly fancy with this section. At least compared to the others.
    :State("STATE_POLITICAL")
        :Loc{
            OPT_GIVE_BREAD = "[p] give bread",
            DIALOG_POLITICAL = [[
                * You find {agent} staring at a poster for the Rise.
                player:
                    This oughta be easy support.
                    Hello {agent}. Care for some Dole Bread?
                agent:
                    Sure. Say, this is rather helpful to the cause
                    Are you in support of a UBI? So this kind of thing doesn't have to happen anymore?
            ]],
            OPT_AGREE = "Agree to their ideas.",
            DIALOG_AGREE = [[
                player:
                    Viva la Rise, am I right?
                agent:
                    Right you are!
                    It's been so long since I met a like-minded politician since Kalandra.
                    And what about those taxes? They bleed the common man dry and keep on draining.
                    You agree, right?
            ]],

            OPT_DISAGREE = "Respectfully disagree with their opinions.",
            DIALOG_DISAGREE = [[
                player:
                    I don't believe my opinion on the topic is of import to this conversation.
                agent:
                    What are you saying?
                    Do you mean you HATE welfare in all forms?
                    Is that what you mean?
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_POLITICAL")
            table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())

            cxt:Opt("OPT_AGREE")
                :UpdatePoliticalStance("WELFARE", 2, false, true)
                :ReceiveOpinion("politic")
                :Dialog("DIALOG_AGREE")
                :GoTo("STATE_AGREE")
            cxt:Opt("OPT_DISAGREE")
                :Dialog("DIALOG_DISAGREE")
                :GoTo("STATE_DISAGREE")
        end)
    :State("STATE_AGREE")
        :Loc{
            OPT_AGREE_2 = "Agree to their second stance.",
            DIALOG_AGREE_2 = [[
                * You agree with their second issue.
                * They absolutely love you. You don't know if anyone else will.
            ]],
            OPT_DISAGREE_2 = "Tell them you don't agree with the second stance.",
            DIALOG_DISAGREE_2 = [[
                player:
                    Now, now. Let's not get ahead of ourselves.
                agent:
                    Why? Why are you deflecting this issue?
                    Is it because you HATE labor laws? Do you WANT people to be treated like bog muck?
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_AGREE_2")
                :UpdatePoliticalStance("LABOR_LAW", 2, false, true)--random stance. might change once I get a minute to look.
                :ReceiveOpinion("political_waffle")
                :Dialog("DIALOG_AGREE_2")
                -- :CompleteQuest("feed_politic")
                :Fn(function(cxt)
                    table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
                end)
                :DoneConvo()
            cxt:Opt("OPT_DISAGREE_2")
                :Dialog("DIALOG_DISAGREE_2")
                :GoTo("STATE_DISAGREE_2")
        end)

    :State("STATE_DISAGREE")
        :Loc{
            OPT_CALM_DOWN = "Tell them how wrong they are.",
            DIALOG_CALM_DOWN = [[
                player:
                    Now that isn't what I meant by it and you know it.
            ]],
            DIALOG_CALM_DOWN_SUCCESS = [[
                player:
                    Do my actions not demonstrate my beliefs?
                    I risked my neck by nabbing bags of these for the people of Havaria.
                agent:
                    I geuss that's true.
                    Pardon, I'm not great at taking rejection for my ideas.
                player:
                    Well, follow the debates. People'll talk all day long about different ideas.
                agent:
                    Can't. I got to get to my next shift.
                player:
                    Well good luck for you, and enjoy the bread
            ]],
            DIALOG_CALM_DOWN_FAIL = [[
                agent:
                    Oh, I get it.
                    You're just trying to butter up the Rise so we'd lay down our arms.
                    You're working with the Barons, aren't you?
                player:
                    No, No, you've got it all-
                agent:
                    Get out of my face, you filthy capitalist. You'll profit no longer from this mere worker.
            ]],
            OPT_IGNORE = "Ignore their complaints, part 1.",
            DIALOG_IGNORE = [[
                * You put on the best poker face you can manage.
                * It doesn't help.
                agent:
                    What? Not going to defend yourself?
                    Try to excuse yourself from hearing the truth?
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_CALM_DOWN")
                :Dialog("DIALOG_CALM_DOWN")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_SUCCESS")
                        -- cxt.quest:Complete("feed_politic")
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_FAIL")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("political_angry"))
                        StateGraphUtil.AddEndOption(cxt)
                    end
                }
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :ReceiveOpinion("political_angry")
                -- :CompleteQuest("feed_politic")
                :DoneConvo()
        end)
    :State("STATE_DISAGREE_2")
        :Loc{
            OPT_CALM_DOWN_2 = "Elaborate on how wrong they are.",
            DIALOG_CALM_DOWN_2 = [[
                * You start telling them exactly how wrong they are, to put it bluntly.
            ]],
            DIALOG_CALM_DOWN_2_SUCCESS = [[
                * You successfully defuse their arguments.
            ]],
            DIALOG_CALM_DOWN_2_FAIL = [[
                * You unsuccessfully defuse their arguments. If anything you gave them more ammo.
            ]],
            OPT_IGNORE_2 = "Ignore their complaints.",
            DIALOG_IGNORE_2 = [[
                * You ignore their verbal bashing.
                * You don't know if they have any influence, because what influence they do have is now against you.
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_CALM_DOWN_2")
                :Dialog("DIALOG_CALM_DOWN_2")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_2_SUCCESS")
                        -- cxt.quest:Complete("feed_politic")
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_2_FAIL")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("political_angry"))
                        StateGraphUtil.AddEndOption(cxt)
                    end
                }
            cxt:Opt("OPT_IGNORE_2")
                :Dialog("DIALOG_IGNORE_2")
                :ReceiveOpinion("political_angry")
                :DoneConvo()
        end)
    :State("STATE_UNGRATEFUL")
        :Loc{
            DIALOG_UNGRATE = [[
                * You approach {agent} and hand them a loaf of bread
                * They look down at it and scowl
                agent:
                    [p] yeah no i'm way too tired for this.
                    blah blah blah screw you.
            ]],
            OPT_CONVINCE = "Try to calm them down",
            DIALOG_CONVINCE = [[
                player:
                    Have you considered not doing that, hm?
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    LaserDisk.
                agent:
                    I'm sold.
                    Have a great day.
            ]],
            DIALOG_CONVINCE_FAIL = [[
                agent:
                    Your deck could be better.
                    Allow me to remind you of this failure for the rest of the run.
            ]],
            OPT_IGNORE = "Ignore their complaints",
            DIALOG_IGNORE = [[
                player:
                    Belt Buckles and globs of bandaids
                agent:
                    POPULIST!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_UNGRATE")
            cxt:Opt("OPT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                        -- cxt.quest:Complete("feed_ungrate")
                        table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_FAIL")
                        -- cxt:ReceiveOpinion("peeved")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("peeved"))
                        table.insert(cxt.quest.param.rejected_people, cxt:GetAgent())
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                }
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :ReceiveOpinion("peeved")
                :Fn(function(cxt)
                    table.insert(cxt.quest.param.rejected_people, cxt:GetAgent())
                end)
                :DoneConvo()
            end)
    :State("STATE_GRATEFUL")
        :Loc{
            DIALOG_GRATE = [[
                player:
                    [p] Hey. Want some bread?
                agent:
                    Sure. Y'know, you're alright.
                    Thanks!
            ]],
            -- Bringing someone just for gifting them is extremely op, so we just repurpose this to be the default response.
            -- OPT_BRING_ALONG = "Let them tag along for a while.",
            -- DIALOG_BRING_ALONG = [[
            --     player:
            --         Come with me. I shall take you to the promised land.
            --     agent:
            --         Wait...are you jesus?
            --     player:
            --         Don't know who jesus is...come on now.
            -- ]],
            -- OPT_DONT = "Don't bring them along.",
            -- DIALOG_DONT_BRING = [[
            --     player:
            --         [p] I don't like the fact ' break code.
            --     agent:
            --         how did you say apostrophe without saying it?
            --     player:
            --         I don't know. thanks for the offer.
            -- ]]
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_GRATE")
            table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo("dole_out_three", "primary_advisor")
    :Loc{
        OPT_END_EARLY = "Finish quest early",
        DIALOG_END_EARLY = [[
            player:
                I'm done.
            agent:
                Wait, really?
                But there's still plenty of time!
            player:
                Nothing else I can do.
            agent:
                Suit yourself, I guess.
        ]],
    }
    :Hub(function(cxt, who)
        cxt:Opt("OPT_END_EARLY")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_END_EARLY")
            :Fn(function(cxt)
                cxt.quest:Complete("time_countdown")
            end)
        cxt:Opt("OPT_ADMIT_DEFEAT")
            :Fn(function(cxt)
                if not cxt.quest:IsComplete("dole_out_three") then
                    cxt:Dialog("DIALOG_ADMIT_DEFEAT")
                    cxt.quest:Fail()
                end
            end)
    end)
QDEF:AddConvo("go_to_advisor", "primary_advisor")
    :Loc{
        OPT_TALK_PROGRESS = "Talk about your progress",
        DIALOG_TALK_PROGRESS = [[
            agent:
                So? How did you do?
        ]],
        DIALOG_NO_GIFT = [[
            player:
                [p] I gifted no one.
            agent:
                Wow you suck.
        ]],
        DIALOG_ONE_GIFT = [[
            player:
                [p] I gifted about one person.
            agent:
                You might as well not do that.
        ]],
        DIALOG_FEW_GIFT = [[
            player:
                [p] I gifted {1} people.
            agent:
                [p] Not great, but not bad either.
        ]],
        DIALOG_MORE_GIFT = [[
            player:
                [p] I gifted {1} people.
            agent:
                [p] You did good.
        ]],
    }
    --This final part is where the issue lies.
    :Hub(function(cxt)
        cxt:Opt("OPT_TALK_PROGRESS")
            :SetQuestMark()
            :Dialog("DIALOG_TALK_PROGRESS")
            :Fn(function(cxt)
                local count = #cxt.quest.param.gifted_people
                if count == 0 then
                    cxt:Dialog("DIALOG_NO_GIFT", count)
                    cxt.quest:Fail()
                elseif count == 1 then
                    cxt:Dialog("DIALOG_ONE_GIFT", count)
                    cxt.quest:Fail()
                elseif count <= 3 then
                    cxt:Dialog("DIALOG_FEW_GIFT", count)
                    cxt.quest.param.poor_performance = true
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                else
                    cxt:Dialog("DIALOG_MORE_GIFT", count)
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                end
            end)
            :DoneConvo()
    end)
