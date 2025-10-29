package com.rakuten.room.reels.flutter

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import io.flutter.embedding.android.FlutterFragment

class FlutterReelsFragment : Fragment() {
    
    private var flutterFragment: FlutterFragment? = null
    
    companion object {
        private const val INITIAL_ROUTE_KEY = "initial_route"
        
        fun newInstance(initialRoute: String = "/"): FlutterReelsFragment {
            val fragment = FlutterReelsFragment()
            val args = Bundle()
            args.putString(INITIAL_ROUTE_KEY, initialRoute)
            fragment.arguments = args
            return fragment
        }
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        val initialRoute = arguments?.getString(INITIAL_ROUTE_KEY) ?: "/"
        
        // Initialize Flutter engine if not already done
        FlutterEngineManager.getInstance().initializeFlutterEngine(requireContext())
        
        val engineManager = FlutterEngineManager.getInstance()
        flutterFragment = FlutterFragment.withCachedEngine(engineManager.getFlutterEngineId())
            .build()
        
        childFragmentManager
            .beginTransaction()
            .add(android.R.id.content, flutterFragment!!)
            .commit()
        
        return flutterFragment?.view
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        flutterFragment?.let {
            childFragmentManager
                .beginTransaction()
                .remove(it)
                .commit()
        }
        flutterFragment = null
    }
}